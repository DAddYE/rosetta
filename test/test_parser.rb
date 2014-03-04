require_relative './helper'

class TestParser < Minitest::Test
  include Rosetta::Ast

  def parse(code, &block)
    @parser = Rosetta::Parser.new
    code = "package code\n#{code.undent}" unless code =~ /\Apackage/
    @parsed = @parser.parse(code.undent)
    @parsed
  end

  def debug!(val=nil)
    pp @parsed
    puts @parser.lexer.pretty_print
    pp val if val
  end

  def test_package
    node = parse('package main')
    assert_kind_of Package, node.package
    assert_equal 'main', node.package.name.value
  end

  def test_import
    imports = parse('import "hello"').imports
    assert_equal 1, imports.size
    import = imports[0]
    assert_kind_of Import, import
    assert_equal nil, import.here
    assert_equal '"hello"', import.there.value

    imports = parse('import _ "hello"').imports
    assert_equal 1, imports.size
    import = imports[0]
    assert_kind_of Import, import
    assert_equal '_', import.here.value
    assert_equal '"hello"', import.there.value

    imports = parse('import . "hello"').imports
    assert_equal 1, imports.size
    import = imports[0]
    assert_kind_of Import, import
    assert_equal '.', import.here
    assert_equal '"hello"', import.there.value

    imports = parse(<<-CODE).imports
      import
        _   "foo/bar"
        bar "foo/bar"
    CODE
    heres = ['_', 'bar']
    imports.each_with_index do |import, i|
      assert_kind_of Import, import
      assert_equal '"foo/bar"', import.there.value
      assert_equal heres[i], import.here.value
    end
  end

  def test_common_dcl
    dcls = parse('var x int').declarations
    dcl = dcls[0]
    assert_kind_of DclVar, dcl
    dcl = dcl.values
    assert_kind_of DclCommon, dcl
    assert_equal 'int', dcl.type.right.value
    assert_equal ['x'], dcl.names.map(&:value)
    assert_equal [], dcl.values

    dcls = parse('var x int = 1').declarations
    dcl = dcls[0]
    assert_kind_of DclVar, dcl
    dcl = dcl.values
    assert_kind_of DclCommon, dcl
    assert_equal 'int', dcl.type.right.value
    assert_equal ['x'], dcl.names.map(&:value)
    assert_kind_of NumericType, dcl.values[0]
    assert_equal '1', dcl.values[0].value

    dcls = parse(<<-CODE).declarations[0]
      var
        x, y string
        a, b int = 0, 2
    CODE
    assert_kind_of DclVar, dcls
    dcls = dcls.values
    assert_kind_of ParensIndent, dcls
    dcl = dcls.value[0]
    assert_kind_of DclCommon, dcl
    assert_equal 'string', dcl.type.right.value
    assert_equal 'x', dcl.names[0].value
    assert_kind_of Comma, dcl.names[1]
    assert_equal 'y', dcl.names[2].value
    assert_equal [], dcl.values
    assert_kind_of Line, dcls.value[1]
    dcl = dcls.value[2]
    assert_kind_of DclCommon, dcl
    assert_equal 'int', dcl.type.right.value
    assert_equal 'a', dcl.names[0].value
    assert_kind_of Comma, dcl.names[1]
    assert_equal 'b', dcl.names[2].value
    assert_equal 3, dcl.values.size
    dcl.values.each_with_index do |num, i|
      next if num.is_a?(Comma)
      assert_kind_of NumericType, num
      assert_equal i.to_s, num.value
    end

    dcls = parse(<<-CODE).declarations[0]
      const
        _ = iota
        x, y string
        a, b int = 0, 2
        z
    CODE
    assert_kind_of DclConst, dcls
    dcls = dcls.values
    assert_kind_of ParensIndent, dcls
    dcl = dcls.value[0]
    assert_kind_of DclCommon, dcl
    assert_equal nil, dcl.type
    assert_equal '_', dcl.names[0].value
    assert_equal 'iota', dcl.values[0].value
    assert_kind_of Line, dcls.value[1]
    dcl = dcls.value[2]
    assert_kind_of DclCommon, dcl
    assert_equal 'x', dcl.names[0].value
    assert_kind_of Comma, dcl.names[1]
    assert_equal 'y', dcl.names[2].value
    assert_equal [], dcl.values
    assert_kind_of Line, dcls.value[3]
    dcl = dcls.value[4]
    assert_kind_of DclCommon, dcl
    assert_equal 'int', dcl.type.right.value
    assert_equal 'a', dcl.names[0].value
    assert_kind_of Comma, dcl.names[1]
    assert_equal 'b', dcl.names[2].value
    assert_equal 3, dcl.values.size
    dcl.values.each_with_index do |num, i|
      next if num.is_a?(Comma)
      assert_kind_of NumericType, num
      assert_equal i.to_s, num.value
    end
    assert_kind_of Line, dcls.value[5]
    dcl = dcls.value[6]
    assert_kind_of DclCommon, dcl
    assert_equal nil, dcl.type
    assert_equal ['z'], dcl.names.map(&:value)
    assert_equal [], dcl.values

    dcls = parse('type my_int int').declarations[0]
    assert_kind_of DclType, dcls
    dcl = dcls.values
    assert_kind_of DclCommon, dcl
    assert_equal 'int', dcl.type.right.value
    assert_equal ['my_int'], dcl.names.map(&:value)
    assert_equal [], dcl.values

    dcls = parse(<<-CODE).declarations[0]
      type
        myInt int
        myString string
    CODE
    assert_kind_of DclType, dcls
    dcls = dcls.values
    assert_kind_of ParensIndent, dcls
    dcl = dcls.value[0]
    assert_kind_of DclCommon, dcl
    assert_equal 'int', dcl.type.right.value
    assert_equal ['myInt'], dcl.names.map(&:value)
    assert_equal [], dcl.values
    assert_kind_of Line, dcls.value[1]
    dcl = dcls.value[2]
    assert_kind_of DclCommon, dcl
    assert_equal 'string', dcl.type.right.value
    assert_equal ['myString'], dcl.names.map(&:value)
    assert_equal [], dcl.values
  end

  def test_fn_declaration
    dcl = parse('def hello()').declarations[0]
    assert_kind_of Function, dcl
    assert_kind_of Function::Name, dcl.name
    assert_kind_of QualifiedIdent, dcl.name.name
    assert_equal 'hello', dcl.name.name.right.value
    assert_equal [], dcl.params
    assert_equal [], dcl.results
    assert_equal nil, dcl.body

    dcls = parse(<<-CODE).declarations
      def **row(tableName **string, values *[]string,
          b *sql.Tx, bool) -> error
        hello
    CODE
    dcl = dcls[0]
    assert_kind_of Function, dcl
    assert_equal 'row', dcl.name.name.right.value
    assert_equal 2, dcl.name.ptr
    assert_equal 1, dcl.body.size
    param = dcl.params[0]
    assert_equal 'tableName', param.name.value
    assert_kind_of PointerType, param.type
    assert_kind_of PointerType, param.type.value # **string pointer to pointer
    assert_equal 'string', param.type.value.value.right.value
    assert_kind_of Comma, dcl.params[1]
    param = dcl.params[2]
    assert_equal 'values', param.name.value
    assert_kind_of PointerType, param.type
    assert_kind_of ArrayType, param.type.value
    assert_equal 'string', param.type.value.type.right.value
    assert_equal nil, param.type.value.length
    assert_kind_of Comma, dcl.params[3]
    param = dcl.params[4]
    assert_equal 'b', param.name.value
    assert_kind_of PointerType, param.type
    assert_kind_of QualifiedIdent, param.type.value
    assert_equal 'sql', param.type.value.left.value
    assert_equal 'Tx', param.type.value.right.value
    assert_kind_of Comma, dcl.params[5]
    param = dcl.params[6]
    assert_kind_of QualifiedIdent, param.name
    assert_equal 'bool', param.name.right.value
  end
end
