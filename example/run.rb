require 'bundler/setup'
require 'rosetta'
require 'pp'

include Rosetta

code = File.read(__dir__ + '/complex.go.ros')

# lexer = Lexer.new(code)
# puts lexer.tokens

# parser = Parser.new
begin
  parser = Parser.new
  ast = parser.parse(code)
  ast.target = :go
  ast.writer = StringIO.new
  IO.popen('gofmt', 'r+', err: [:child, :out]) do |io|
    ast.target = :go
    ast.writer = io
    ast.compile!
    out = io.read

    # Prettify the output: 123 | code
    max = ast.buff.lines.size
    ast.buff.lines.each_with_index do |l, i|
      print "#{i+1} | ".rjust("#{max}".size + 4)
      puts l
    end

    if out =~ /:(\d+):(\d+):/
      tk = parser.tokens.detect { |t| next unless t.destination; t.destination.first_line == $1.to_i }
      puts out
      puts code.lines[tk.source.first_line]
      puts '-- In your ros source: --'
      puts out.sub(/:(\d+):(\d+):/, ":#{tk.source.first_line}:#{tk.source.first_column}:")
      puts ast.buff.lines[$1.to_i]
    end

    puts out
  end
rescue
  # puts parser.lexer.pretty_print
  raise
end
