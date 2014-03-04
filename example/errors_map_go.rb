require 'bundler/setup'
require 'rosetta'

code = <<-CODE
package main
import "fmt"

def main()
  s := "Darkneeeeees, in the basement..."
  x := 'error here'
CODE

parser = Rosetta::Parser.new
ast = parser.parse(code)

# Pass directly to an IO
IO.popen('gofmt', 'r+', err: [:child, :out]) do |io|
  ast.target = :go
  ast.writer = io
  ast.compile!
  error = io.read

  # <standard input>:7:7: illegal character literal
  _, line, _ = *error.match(/:([0-9]+):([0-9]+):/)

  # Find tokens that match this line/column in the destination
  token = parser.tokens.detect do |token|
    next unless token.destination
    token.destination.first_line == line.to_i - 1
  end

  puts error
  puts code.lines[token.source.first_line]

  # rosetta [golang*] $ ruby example/errors_map_go.rb
  # <standard input>:7:7: illegal character literal
  #   x := 'error here'
end
