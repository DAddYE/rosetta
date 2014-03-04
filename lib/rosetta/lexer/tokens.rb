module Rosetta
  class Lexer
    class Token < Array
      attr_accessor :spaced, :new_line, :string_end, :source, :destination

      def tag
        self[0]
      end

      def value
        self[1]
      end
    end

    class Tokens
      ALL = { :* => :* }

      # Little class to avoid RY
      class Listener < Hash
        def initialize
          self.default_proc = ->(h,k){ h[k] = [] }
        end
      end

      def initialize(*args)
        @_tokens = []
        @_listeners = Hash.new { |h,k| h[k] = Listener.new }
      end

      # tokens.on(:push, TERMINATOR: "\n") {  }
      # tokens.on(:push, :TERMINATOR, :FOR){  }
      def on(*tags, &block)
        event = tags.shift.to_sym
        keys  = tags.reduce({}) do |m, (k, v)|
          k.is_a?(Hash) ? m.merge!(k) : m[k] = v
          m
        end
        keys.merge!(ALL) if keys.empty?
        keys.map do |tag, value|
          callback = ->(token, me) do
            if tag == :* && value == :*
              block[token, me]
            elsif value && token[0] == tag && token[1] == value
              block[token, me]
            elsif token[0] == tag
              block[token, me]
            end
          end
          # Cascade match
          key = value ? [tag, value] : tag
          @_listeners[event][key] << callback
          callback.object_id
        end
      end

      def once(*tags, &block)
        event = tags[0].to_sym
        on(*tags) do |token, me|
          ret = block[token, me]
          @_listeners[event][token[0]].delete_if { |cb| cb == me }
          @_listeners[event][token].delete_if    { |cb| cb == me }
          @_listeners[event][*ALL].delete_if     { |cb| cb == me }
          ret
        end
      end

      # def each(*a, &b)
      #   @_tokens.each(*a, &b)
      # end

      def emit(event, token)
        @_listeners[event][token[0]].each { |cb| cb[token, cb] } if @_listeners[event].has_key?(token[0])
        @_listeners[event][token].each    { |cb| cb[token, cb] } if @_listeners[event].has_key?(token)
        @_listeners[event][*ALL].each     { |cb| cb[token, cb] } if @_listeners[event].has_key?(*ALL)
      end

      def push(token)
        ret = @_tokens.push(token)
        emit(:push, token)
        ret
      end

      def [](val)
        @_tokens[val]
      end

      def pop
        return unless ret = @_tokens.pop
        emit(:pop, ret)
        ret
      end

      def delete_at(val)
        return unless ret = @_tokens.delete_at(val)
        emit(:delete_at, ret)
        ret
      end

      def shift
        return unless ret = @_tokens.shift
        emit(:shift, ret)
        ret
      end

      def empty?
        @_tokens.empty?
      end

      def size
        @_tokens.size
      end

      def to_a
        @_tokens
      end
    end
  end
end
