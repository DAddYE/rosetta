module Rosetta::Ast

  class NotSupported < RuntimeError
  end

  class Base
    class << self

      def has(*args)
        args.each do |property|
          attr_accessor property
          properties.delete(property) # for repositioning
          properties.push property
        end
      end

      def properties
        @properties ||= []
      end

      def inherited(base)
        base.has(*properties)
      end

    end

    def initialize(*attrs)
      raise "#{self.class} expect: #{properties}, got: #{attrs}" if !attrs.empty? && attrs.size != properties.size
      attrs.each_with_index do |val, i|
        send(:"#{properties[i]}=", val)
      end
    end

    def properties
      self.class.properties
    end

    def store_position(txt)
      @@position[0] += txt.count("\n")
      @@position[1]  = txt.size

      return unless respond_to?(:token)

      raise "#{self} must have a token" if token.nil?

      if dest = token.destination
        dest.last_line, dest.last_column = *@@position
      else
        dest = token.destination = Rosetta::Lexer::Location.new
        dest.first_line, dest.first_column = *@@position
      end
    end

    @@mutex    = Mutex.new
    @@indent   = 0
    @@buff     = ""
    @@position = [0, 0]

    def print(txt)
      @@mutex.synchronize do
        @@indent.times do
          writer << "\t"
          buff   << "\t"
        end if buff[-1] == ?\n && !txt.empty?
        writer << txt
        buff << txt
        store_position(txt)
      end
    end

    def writer=(io)
      @@writer=io
    end

    def writer
      @@writer
    end

    def target=(io)
      @@target=io
    end

    def target
      @@target
    end

    def indent(&block)
      @@indent += 1
      block[self]
      puts
    ensure
      @@indent -= 1
    end

    def buff
      @@buff
    end

    def puts(txt='')
      print "#{txt}\n"
    end

    def space(times=1)
      print ' '.rjust(times)
    end

    def tab(times=1)
      print "\t".rjust(times)
    end

    def consume(elements)
      Array(elements).each do |el|
        case el
        when NilClass
          # Nothing for now
        when Array
          consume(el)
        else
          m_name = :"to_#{target}"
          if el.respond_to?(m_name)
            el.send(m_name)
          else
            raise "#{self.class} has a value `#{el.inspect}` " <<
              "in #{elements}, which does not implement `#{m_name}`"
          end
        end
      end
    end

    def to_common_target
      properties.map do |name|
        property = send(name)
        consume(property)
      end
    end

    def to_go
      to_common_target
    end

    def to_ruby
      to_common_target
    end

    def go_block(indent=true, &block)
      print " {\n"
      if indent
        indent { block[self] }
      else
        block[self]
      end
      print "}"
    end

    def new_line
      puts
    end

    def ruby_block(indent=true, &block)
      puts
      if indent
        indent { block[self] }
      else
        block[self]
      end
      puts 'end'
    end
  end

  class Root < Base
    has :package,
        :imports,
        :declarations

    def compile
      consume package
      consume imports
      consume declarations
      writer.close_write
      true
    end
    alias compile! compile
  end

  class Package < Base
    has :name

    def to_go
      print 'package '
      consume name
      puts
      puts
    end

    def to_ruby
      raise NotSupported, 'package'
    end
  end

  class Import < Base
    has :here, :there

    def to_go
      print 'import '
      if here
        consume here
        space
      end
      consume there
      puts
    end

    def to_ruby
      print 'require '
      raise NotSupported, "import as `#{here}`" if here
      consume there
      puts
    end
  end

  class DclCommon < Base
    has :names, :type, :values

    def to_go
      consume names
      space
      consume type
      unless values.empty?
        print ' = '
        consume values
      end
    end

    def to_ruby
      raise NotSupported, 'defining types is not supported for this target' if type
      consume names
      space
      print ' = '
      consume values
    end
  end

  class DclVar < Base
    has :values

    def to_go
      print 'var'
      space
      consume values
    end

    def to_ruby
      consume values
    end
  end

  class DclConst < Base
    has :values

    def to_go
      print 'const'
      space
      consume values
    end
  end

  class DclType < Base
    has :values

    def to_go
      print 'type'
      space
      consume values
    end
  end

  class DclModule < Base
    has :name,  :declarations

    def to_ruby
      print 'module '
      consume name
      ruby_block { consume declarations }
    end
  end

  class DclClass < Base
    has :name, :superclass, :declarations

    def to_ruby
      print 'class '
      consume name
      if superclass
        print ' < '
        consume superclass
      end
      ruby_block { consume declarations }
    end
  end

  class StmtLabeled < Base
    has :label, :statement

    def to_go
      print label
      print ':'
      indent { consume statement }
    end
  end

  class StmtFall < Base
    has :token

    def to_go
      print 'fallthrough'
    end
  end

  class StmtBreak < Base
    has :value

    def to_go
      print 'break '
      consume value
    end

    alias to_ruby to_go
  end

  class StmtContinue < Base
    has :value

    def to_go
      print 'continue '
      consume value
    end
  end

  class StmtGo < Base
    has :value

    def to_go
      print 'go '
      consume value
    end
  end

  class StmtDefer < Base
    has :value

    def to_go
      print 'defer '
      consume value
    end
  end

  class StmtGoto < Base
    has :value

    def to_go
      print 'goto '
      consume value
    end
  end

  class StmtReturn < Base
    has :value

    def to_go
      print 'return '
      consume value
    end

    alias to_ruby to_go
  end

  class Function < Base
    has :name, :params, :results, :body

    def to_go
      puts if name

      print 'func'

      if name
        space
        consume name
      end

      # Params
      print '('; consume params; print ')'

      if results && !results.empty?
        print ' ('; consume results; print ')'
      end

      go_block { consume body } if body
    end

    def to_ruby
      puts if name

      print 'def '

      consume name

      unless params.empty?
        print '('; consume params; print ')'
      end

      ruby_block { consume body }
    end

    class Name < Base
      has :ptr, :name, :special

      def to_go
        raise NotSupported, "`#{special}` is not supported by golang" if special

        if name.left
          print '(self '
          ptr.times { print '*' }
          consume name.left; print ') '
        end

        consume name.right if name.right
      end

      def to_ruby
        raise NotSupported, 'pointer is not supported' if ptr > 0

        consume name
        consume special
      end
    end
  end

  class FunctionDo < Function
    def to_ruby
      print '->('; consume params; print ')'
      ruby_block { consume body }
    end
  end

  class QualifiedIdent < Base
    has :left, :qualifier, :right

    def to_go
      if left
        consume left
        print qualifier
      end
      consume right
    end

    alias to_ruby to_go
  end

  class PointerType < Base
    has :value

    def to_go
      print '*'; consume(value)
    end
  end

  class Variadic < Base
    has :type

    def to_go
      print '...'; consume(type)
    end

    def to_ruby
      print '*'; consume(type)
    end
  end

  class ArrayType < Base
    has :length, :type

    def to_go
      print '['
      consume(length) if length
      print ']'
      consume(type)
    end
  end

  class Literal < Base
    has :value, :token

    def to_go
      print value
    end

    alias to_ruby to_go
  end

  class StringType < Literal

    def to_go
      print value
    end
  end

  class NumericType < Literal
  end

  class RegexType < Literal
    def to_go
      escaped = value
      if escaped[0] == ?/
        escaped = escaped[1..-1]
      end
      if i = escaped.rindex('/')
        escaped = escaped[0...i]
      end
      print "`"; print escaped; print "`"
    end
  end

  class InstanceVar < Literal
    def to_ruby
      print '@'
      super
    end
  end

  class ClassVar < Literal
    def to_ruby
      print '@@'
      super
    end
  end

  class Param < Base
    has :name, :type

    def to_go
      consume(name)
      if type
        space
        consume(type)
      end
    end

    def to_ruby
      raise NotSupported, 'defining types is not supported by ruby' if type
      consume name
    end
  end

  class Line < Base

    def to_go
      puts
    end

    alias to_ruby to_go
  end

  class Comma < Base
    def to_go
      print ', '
    end
    alias to_ruby to_go
  end

  class Semicolon < Base
    def to_go
      print '; '
    end
    alias to_ruby to_go
  end

  class Expr < Base
    has :left, :operator, :right

    def to_go
      consume left
      space unless unary?
      print operator
      space unless unary?
      consume right
    end

    def unary?
      Array(left).empty?  ||
      Array(right).empty?
    end
    alias to_ruby to_go
  end

  class ExprIndex < Base
    has :left, :size

    def to_go
      consume left
      print '['; consume(size); print ']'
    end
    alias to_ruby to_go
  end

  class ExprSlice < Base
    has :left, :low, :high, :max

    def to_go
      consume left
      print '['
      consume low
      if high
        print ':'
        consume high
      end
      print ':'
      consume max
      print ']'
    end

    def to_ruby
      consume left
      print '['
      if low
        consume low
        print '..'
      end
      if high
        print '-' unless low
        consume high
      end
      raise NotSupported, 'defining max is not supported by ruby' if max
      print ']'
    end
  end

  class ExprSelector < Base
    has :left, :right

    def to_go
      if left
        consume left
        print '.'
      end
      consume right
    end

    alias to_ruby to_go
  end

  class ExprTypeAssert < Base
    has :left, :right

    def to_go
      consume left
      print '.('; consume right; print ')'
    end
  end

  class Switch < Base
    has :header, # 0, 1 or 2 simple statement + expression
        :cases   # Array of Switchcase

    def to_go
      print 'switch '
      consume header
      go_block(false) { consume cases }
    end

    def to_ruby
      print 'case '
      consume header
      ruby_block(false){ consume cases }
    end
  end

  class Select < Base
    has :cases   # Array of Switchcase

    def to_go
      print 'select '
      go_block(false) { consume cases }
    end
  end

  class SwitchCase < Base
    has :kind,       # case, default
        :expression, # expression or type guard
        :statements

    def to_go
      print kind
      if expression
        space
        consume expression
      end
      puts ':'
      indent { consume statements }
    end

    def to_ruby
      case kind
      when :case then print 'when'
      when :default then print 'else'
      end
      if expression
        space
        consume expression
      end
      puts
      indent { consume statements }
    end
  end

  class Parens < Base
    has :value

    def to_go
      print '('; consume(value); print ')'
    end
    alias to_ruby to_go
  end

  class ParensIndent < Base
    has :value

    def to_go
      print '('
      new_line
      indent { consume(value) }
      print ')'
    end
    alias to_ruby to_go
  end

  class Call < Base
    has :value, :special, :args, :splat

    def to_go
      consume value
      print '('
      consume args
      print '...' if splat
      print ')'
    end

    def to_ruby
      consume value
      if fndo = args[-1] and fndo.is_a?(FunctionDo)
        consume args[0..-2]
        print ' do'
        unless fndo.params.empty?
          print ' |'; consume fndo.params; print '|'
        end
        ruby_block { consume fndo.body }
      else
        print '('
        consume args[0..-2]
        print '*' if splat
        consume args[-1]
        print ')'
      end
    end
  end

  class Conversion < Call
  end

  class CompLiteral < Base
    has :type, :value

    def to_go
      consume type
      print '{'; consume value; print '}'
    end
  end

  class MapType < Base
    has :key_type, :type

    def to_go
      print 'map['
      consume key_type
      print ']'
      consume type
    end
  end

  class KeyType < Base
    has :key, :value

    def to_go
      consume key
      print ': '
      consume value
    end
  end

  class StructType < Base
    has :fields

    def to_go
      print 'struct'
      go_block { consume fields }
    end

    class Field < Base
      has :identfiers,
          :type,
          :tag,
          :anonymous

      def to_go
        print '*' if anonymous
        consume identfiers
        if type
          tab
          consume type
        end
        if tag
          tab
          consume tag
        end
      end
    end
  end

  class InterfaceType < Base
    has :specs

    def to_go
      print 'interface'
      go_block { consume specs }
    end

    class Spec < Base
      has :name, :signature, :type
    end
  end

  class If < Base
    has :header, :body, :else_if, :else_

    def to_go
      print 'if '
      consume header
      go_block { consume body }
      consume else_if unless else_if.empty?
      consume else_  if else_
    end

    class Header < Base
      has :statements
    end

    class ElseIf < Base
      has :header, :body

      def to_go
        print 'else if '
        consume header
        go_block { consume body }
      end

      def to_ruby
        print 'elsif '
        consume header
        go_block { consume body }
      end
    end

    class Else < Base
      has :body

      def to_go
        print 'else '
        go_block { consume body }
      end
      alias to_ruby to_go
    end
  end

  class For < Base
    has :header, :body

    def to_go
      print 'for '
      consume header
      go_block { consume body }
    end
  end

  class Range < Base
    has :expr

    def to_go
      print 'range '
      consume expr
    end
  end

  module ChanType

    class SendRecv < Base
      has :type

      def to_go
        print 'chan '
        consume type
      end
    end

    class Send < Base
      has :type

      def to_go
        print 'chan<- '
        consume type
      end
    end

    class Recv < Base
      has :type

      def to_go
        print '<- '
        consume type
      end
    end
  end
end
