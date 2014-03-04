class Rosetta::Lexer
  class Location
    attr_accessor :first_line, :first_column,
                  :last_line, :last_column

    def initialize(*a)
      @first_line   = a[0]
      @first_column = a[1]
      @last_line    = a[2]
      @last_column  = a[3]
    end

    def to_a
      [@first_line, @first_column, @last_line, @last_column]
    end

    def to_s
      "#{last_line}:#{last_column}"
    end

    def inspect
      "ln:#{first_line}..#{last_line}, col:#{first_column}..#{last_column}"
    end
  end
end
