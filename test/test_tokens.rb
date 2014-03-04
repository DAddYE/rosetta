require_relative './helper'

class TestTokens < Minitest::Test
  include LexerHelpers

  def setup
    @tokens = Rosetta::Lexer::Tokens.new
  end

  def test_acts_as_array
    assert_equal [:a], @tokens.push(:a)
    assert_equal :a, @tokens[0]
    assert_equal  1, @tokens.size
    assert_equal :a, @tokens.pop
    assert @tokens.empty?
  end

  def test_on
    current = nil
    @tokens.on(:push, :TERMINATOR) { |t| current = t }
    @tokens.push [:TERMINATOR, ':']
    assert_equal [:TERMINATOR, ':'], current
  end

  def test_once
    current = []
    @tokens.once(:push, :TERMINATOR) { |t| current << t }
    @tokens.push([:TERMINATOR, ':'])
    assert_equal [[:TERMINATOR, ':']], current
    @tokens.push([:TERMINATOR, ':'])
    assert_equal [[:TERMINATOR, ':']], current
  end

  def test_on_array
    current = nil
    @tokens.on(:push, :TERMINATOR, :FOR) { |t| current = t }
    @tokens.push [:TERMINATOR, ':']
    assert_equal [:TERMINATOR, ':'], current
  end

  def test_on_hash
    # Nothing matched
    current = []
    @tokens.on(:push, TERMINATOR: "\n") { |t| current << t }
    @tokens.push([:TERMINATOR, ':'])
    assert_equal [], current

    # Match 1 event
    current = []
    @tokens.on(:push, TERMINATOR: ':') { |t| current << t }
    @tokens.push [:TERMINATOR, ':']
    assert_equal [[:TERMINATOR, ':']], current

    # Match 2 events
    current = []
    @tokens.on(:push, :TERMINATOR) { |t| current << t }
    @tokens.push [:TERMINATOR, ':']
    assert_equal [[:TERMINATOR, ':'], [:TERMINATOR, ':']], current
  end

  def test_pop
    current = []
    @tokens.push [:TERMINATOR, ':']
    @tokens.on(:pop, TERMINATOR: ':') { |t| current << t }
    token = @tokens.pop
    assert_equal [token], current
  end

  def test_shift
    current = []
    @tokens.push [:TERMINATOR, ':']
    @tokens.push [:INDENT, 2]
    @tokens.on(:shift, TERMINATOR: ':') { |t| current << t }
    token = @tokens.shift
    assert_equal [token], current
    @tokens.shift
    assert_equal [token], current
  end

  def test_all_events
    current = []
    @tokens.on(:push) { |t| current << t }
    @tokens.push [:TERMINATOR, ':']
    assert_equal [[:TERMINATOR, ':']], current
    @tokens.push [:INDENT, 2]
    assert_equal [[:TERMINATOR, ':'], [:INDENT, 2]], current
  end
end
