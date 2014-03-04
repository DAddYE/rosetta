require 'bundler/setup'
require 'minitest/pride'
require 'minitest/autorun'
require 'rosetta'
require 'pp'
require 'pry'

class Minitest::Test
  make_my_diffs_pretty!
  # parallelize_me!
  # Cit. In doing so, you're admitting that you rule and your tests are awesome.
end

##
# Few helpers
#
class String
  def undent
    if self =~ /\A\n?( +)/
      gsub(/^#{$1}/, '')
    else
      self
    end
  end
end

module LexerHelpers
  def assert_token_column(token, code, msg="")
    location = token.source
    lines = code.split("\n")[location.first_line..location.last_line].join("\n")
    assert_equal token.value,
      lines[location.first_column..location.last_column], msg
  end

  def assert_token(token, tag, value, source, o={})
    assert_equal tag, token.tag, 'Wrong token tag'
    assert_equal value, token.value, "Wrong #{tag} token value"
    return if o[:skip_location] || [:TERM, :INDENT, :OUTDENT, '(', ')'].include?(tag)
    assert_token_column token, source,
      'Source code does not match token location'
  end

  class TokenArray < Array
    alias :has :push
  end

  def assert_tokens(code, &block)
    code   = code.undent
    lexer  = Rosetta::Lexer.new(code)
    tokens = lexer.tokenize!
    tests  = TokenArray.new
    tests  = block.arity == 0 ? tests.instance_eval(&block) : block[tests]
    i      = -1
    tests.push(TERM: "\n") unless tests[-1][:TERM]
    while tests[i+=1]
      tag, val = tests[i].to_a[0]
      assert_kind_of Rosetta::Lexer::Token, tokens[i]
      assert_token(tokens[i], tag, val, code, tests[i])
    end
    assert_nil tokens[i]
  rescue Minitest::Assertion => e
    msg = <<-MSG.undent
      #{e.message}

       On code:
      #{code}
        Tokens:

    MSG
    msg << lexer.pretty_print
    raise Minitest::Assertion, msg.chomp
  end
end
