require_relative './helper'

class TestLexer < Minitest::Test
  include LexerHelpers

  def test_empty
    assert_tokens(''){ has TERM: "\n" }
  end

  def test_identifier
    assert_tokens('Hello'){ has NAME: 'Hello' }
    code = <<-CODE
      Hello:
        this was
      mine
    CODE
    assert_tokens code do
      has NAME: 'Hello'
      has ':' => ':'
      has INDENT: 2
      has NAME: 'this'
      has NAME: 'was'
      has OUTDENT: 2
      has TERM: "\n"
      has NAME: 'mine'
    end
  end

  def test_numbers
    assert_tokens('123')       { has NUMBER: '123' }
    assert_tokens('123.152')   { has NUMBER: '123.152' }
    skip 'Problem with assert_equal and binary/octal/hex'
    assert_tokens('0b010101')  { has NUMBER: '0b010101' }
  end

  def test_strings
    assert_tokens('"hello"') { has STRING: '"hello"' }
    assert_tokens("'hello'") { has STRING: "'hello'" }
  end

  def test_string_interpolate
    skip
    assert_tokens('"number: #{1}"') do
      has '(' => '('
      has STRING: '"number: "', skip_location: true
      has '+' => '+',           skip_location: true
      has NUMBER: '1',          skip_location: true
      has ')' => ')',           skip_location: true
    end
  end

  def test_heredoc
    code = <<-CODE
    """
    This is a neat
    string on a new line
    """
    CODE
    assert_tokens code do
      has STRING: '"This is a neat\\nstring on a new line"', skip_location: true
    end
  end

  def test_heredoc_indent
    code = <<-CODE
      """
      This is a neat
      string on a new line
      """
    CODE
    assert_tokens code do
      has STRING: '"This is a neat\\nstring on a new line"', skip_location: true
    end
    code = <<-CODE
      """
        This is a neat
        string on a new line
      """
    CODE
    assert_tokens code do
      has STRING: '"This is a neat\\nstring on a new line"', skip_location: true
    end
  end

  def test_heredoc_interpolate
    skip
  end

  def test_regexp
    assert_tokens("/simple/"){ has REGEX: '/simple/' }
  end

  def test_heregex
    assert_tokens("///neat///") do
      has REGEX: '/neat/',      skip_location: true
    end
  end

  def test_heregex_interpolate
    skip
  end

  def test_properties
    assert_tokens "hello: world" do
      has NAME: 'hello'
      has ':' => ':'
      has NAME: 'world'
    end
    code = <<-CODE
      hello:
        my: world
        planet: Earth
    CODE
    assert_tokens code do
      has NAME: 'hello'
      has ':' => ':'
      has INDENT: 2
      has NAME: 'my'
      has ':' => ':'
      has NAME: 'world'
      has TERM: "\n"
      has NAME: 'planet'
      has ':' => ':'
      has NAME: 'Earth'
      has OUTDENT: 2
    end
  end

  def test_callable
    assert_tokens('def hello(): world') do
      has DEF: 'def'
      has NAME: 'hello'
      has '(' => '('
      has ')' => ')'
      has ':' => ':'
      has NAME: 'world'
    end
  end

  def test_callable_multiline
    code = <<-CODE
      def hello():
        world
    CODE
    assert_tokens(code) do
      has DEF: 'def'
      has NAME: 'hello'
      has '(' => '('
      has ')' => ')'
      has ':' => ':'
      has INDENT: 2
      has NAME: 'world'
      has OUTDENT: 2
    end
  end

  def test_params_on_multiline
    code = <<-CODE
      def hello(my
         ,world): works
    CODE
    assert_tokens(code) do
      has DEF: 'def'
      has NAME: 'hello'
      has '(' => '('
      has NAME: 'my'
      has ',' => ','
      has NAME: 'world'
      has ')' => ')'
      has ':' => ':'
      has NAME: 'works'
    end
  end

  def test_multiline
    # skip 'This should not be a call!'
    # assert_tokens('def hello()'){ has FOX: 1 }
    # assert_tokens('def hello():'){ has FOX: 1 }
    skip
    code = <<-CODE.undent
      hello
        .world()
          .neat()
        foxy:
          this:
            is:
              awesome
    CODE
    assert_tokens(code){has FOX: 1}
  end

  def test_reserved_words
    skip
  end

  def test_for
    skip
  end

  def test_for_in
    skip
  end

  def test_line_continuer
    # code = <<-CODE
    # this \
    #   .will \
    #   .work \
    #   .nicely
    # CODE
    skip
  end

  def test_comment
    skip
  end

  def test_withespace
    skip
  end

  def test_line
    skip
  end

  def test_literal
    skip
  end
end
