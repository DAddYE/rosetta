require 'bundler/setup'
require 'rosetta'

# run with DEBUG=1 to see tokens.
Rosetta::Parser.new.parse('def invalid:')

# [stdin]:1:1 Error: line 0: syntax error, for ':' unexpected ":" analyzing (Rosetta::ParseError)
# def invalid:
# ^
# [DEF "def"] [NAME "invalid"] [: ":"] [TERM "\n"]
