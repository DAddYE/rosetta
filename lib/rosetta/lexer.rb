class Rosetta::Lexer
  include Constants

  class Id < String
    attr_accessor :reserved
  end

  include Rosetta::ErrorHelper

  attr_accessor :opts, :tokens, :code

  # Extracted/Adapted from Jashkenas coffee lexer.
  def initialize(code, options = {})
    @opts          = options
    @indent        = 0   # The current indentation level.
    @base_indent   = 0   # The overall minimum indentation level
    @indebt        = 0   # The over-indentation at the current level.
    @outdebt       = 0   # The under-outdentation at the current level.
    @indents       = []  # The stack of all current indentation levels.
    @ends          = []  # The stack for pairing up tokens.
    @tokens        = Tokens.new
    @chunk_line    = options[:line] || 0
    @chunk_column  = options[:column] || 0
    @code          = clean(code)
  end

  def verbose?
    @opts[:verbose]
  end

  # Preprocess the code to remove leading and trailing whitespace, carriage
  # returns, etc.
  def clean(code)
    code = code.slice(1) if code[0] == BOM
    code.gsub!(/\r/, '')
    code.gsub!(TRAILING_SPACES, '')
    if code =~ WHITESPACE
      code = "\n#{code}"
      @chunk_line -= 1
    end
    code
  end

  # Allow thirdy party parser to customize each parsing steps
  def consume!
    empty_line         ||
    name_token         ||
    comment_token      ||
    whitespace_token   ||
    line_token         ||
    heredoc_token      ||
    string_token       ||
    number_token       ||
    regex_token        ||
    literal_token
  end

  def tokenize!
    # At every position, run through this list of attempted matches,
    # short-circuiting if any of them succeed. Their order determines precedence:
    # `@literal_token` is the fallback catch-all.
    i = 0
    while i < @code.size
      @chunk = @code[i..-1]

      consumed = consume!

      if !consumed || consumed.zero?
        raise_syntax_error! "Nothing to consume at #{@chunk_column+i}\n#{@chunk}"
      end

      # Update position
      @chunk_line, @chunk_column = *get_line_and_column_from_chunk(consumed)

      i += consumed
    end

    close_indentation!

    if tag = @ends.pop
      raise_syntax_error! "missing #{tag}"
    end

    @tokens
  end

  def empty_line
    return unless match = @chunk.match(/\A\n{2,}/)
    return match[0].size - 1 # 1 is the new TERM
  end

  def name_token
    return unless match = @chunk.match(IDENTIFIER)

    input, id = *match
    id = Id.new(id)

    new_tag = TOKENS.fetch(id, :NAME)
    new_tag = :NAME if value == '.'

    id.reserved = RESERVED.include?(id)

    # Check if we are using an alias
    if op = ALIASES[id.to_sym]
      new_tag = op
      id = op
    end

    if new_tag == :FOR
      @in_for = true
      @tokens.once(:push, :TERM, :INDENT, ':'){ @in_for = false }
    elsif id == 'in' && @in_for
      new_tag = :IN
    end

    # Prevent parsing dance with if else elseif and make it a compound statement
    @tokens.pop if new_tag == :ELSE && tag == :TERM

    token(new_tag, id)

    return input.size
  end

  # Matches numbers, including decimals, hex, and exponential notation.
  # Be careful not to interfere with ranges-in-progress.
  def number_token
    return unless match = @chunk.match(NUMBER)
    number = match[0]
    lexed_length = number.size
    token(:NUMBER, number, 0, lexed_length)
    lexed_length
  end

  # Matches strings, including multi-line strings. Ensures that quotation marks
  # are balanced within the string's contents, and within nested interpolations.
  def string_token
    quote  = @chunk[0]
    string =
      case quote
      when ?' then @chunk.match(SIMPLESTR)[0]
      when ?" then balanced_string(@chunk, '"')
      end
    return unless string
    if string.index('#{')
      interpolate_string(string, str_offset: 1, lexed_length: string.size)
    else
      token(:STRING, escape(string), 0, string.size)
    end
    string.size
  end

  # Matches heredocs, adjusting indentation to the correct level, as heredocs
  # preserve whitespace, but ignore indentation to the left.
  def heredoc_token
    return unless match = @chunk.match(HEREDOC)
    heredoc = match[0]
    quote = heredoc[0]
    doc = sanitize_heredoc(match[2], quote: quote, indent: nil)
    if quote == '"' && doc.index('#{')
      interpolate_string(doc, heredoc: true, str_offset: 3, lexed_length: heredoc.size)
    else
      token(:STRING, quote + escape(doc) + quote, 0, heredoc.size)
    end
    heredoc.size
  end

  # Matches and consumes comments.
  def comment_token
    return unless match = @chunk.match(COMMENT)
    # _, comment = *match
    # token(:COMMENT, comment, 0, comment.size)
    match[0].size
  end

  # Matches regular expression literals. Lexing regular expressions is difficult
  # to distinguish from division, so we borrow some basic heuristics from
  # JavaScript and Ruby.
  def regex_token
    return if @chunk[0] != '/'
    length = heregex_token
    return length if length
    prev = @tokens[-1]
    return if prev && (prev.spaced ? NOT_REGEX : NOT_SPACED_REGEX).include?(prev[0])
    return unless match = @chunk.match(REGEX)
    match, regex, flags = *match
    # Avoid conflicts with floor division operator.
    return if regex == '//'
    if regex[0..1] == '/*'
      raise_syntax_error! 'regular expressions cannot begin with `*`'
    end
    token(:REGEX, "#{regex}#{flags}", 0, match.size)
    match.size
  end

  # Matches multiline extended regular expressions.
  def heregex_token
    return unless match = @chunk.match(HEREGEX)
    heregex, body, flags = *match
    unless body.index('#{')
      re = escape(body.gsub(HEREGEX_OMIT, '\1\2'))
      token(:REGEX, "/#{ re || '(?:)' }/#{flags}", 0, heregex.size)
      return heregex.size
    end
    tokens = []
    interpolate_string(body, regex: true).each do |token|
      tag, value = *token
      if tag == :TOKENS
        tokens.push(*value)
      elsif tag == :NEOSTRING
        value = value.gsub(HEREGEX_OMIT, '\1\2')
        next unless value
        # Convert NEOSTRING into STRING
        value = value.gsub(/\\/, '\\\\')
        token[0] = :STRING
        token[1] = value
        tokens.push token
      else
        raise_syntax_error! "Unexpected #{tag}"
      end

      prev = @tokens[-1]
      plus_token = Token.new(['+', '+'])
      plus_token.source = prev.source.dup
      tokens.push plus_token
    end
    # Remove the extra "+"
    tokens.pop()

    unless tokens[0] == :STRING
      token(:STRING, '""', 0, 0)
      token('+', '+', 0, 0)
    end
    @tokens.push(*tokens)

    if flags
      # Find the flags in the heregex
      flags_offset = heregex.rindex(flags)
      token(',', ',', flags_offset, 0)
      token(:STRING, '"' + flags + '"', flags_offset, flags.size)
    end

    token(')', ')', heregex.size-1, 0)
    heregex.size
  end

  # Matches newlines, indents, and outdents, and determines which is which.
  # If we can detect that the current line is continued onto the the next line,
  # then the newline is suppressed:
  #
  #     elements
  #       .each( ... )
  #       .map( ... )
  #
  # Keeps track of the level of indentation, because a single outdent token
  # can close multiple indents, so we need to know how far in we happen to be.
  def line_token
    return unless match = @chunk.match(MULTI_DENT)

    indent, _  = *match
    size       = indent.size - 1
    incomplete = unfinished

    #
    # elements.
    # ...foo. <- size: 4, indebt: 0, indent: 0
    # ...bar. <- size: 4, indebt: 4, indent: 4
    # -- case 1. finished && outdented
    # batman <- size: 0, indebt: 4, indent: 0
    # -- case 2. finished && same indent
    # ...batman size: 4, indebt: 4, indent: 4
    #
    if size - @indebt == @indent
      incomplete ? suppress_newlines : newline_token(0)
      return indent.size
    end

    if size > @indent
      if incomplete
        @indebt = size - @indent
        suppress_newlines
        return indent.size
      end
      if @tokens.size.zero?
        @base_indent = @indent = size
        return indent.size
      end
      indent_token(size, indent.size - size)
    elsif size < @base_indent
      raise_syntax_error! 'missing indentation'
    else
      @indebt = 0
      outdent_token(@indent - size, incomplete, indent.size)
    end

    indent.size
  end

  def indent_token(move_in, offset=0, size=move_in)
    diff = move_in - @indent + @outdebt
    token(:INDENT, diff, offset, size)
    @indents.push diff
    @ends.push :OUTDENT
    @outdebt = @indebt = 0
    @indent = move_in
  end

  # Record an outdent token or multiple tokens, if we happen to be moving back
  # inwards past several recorded indents. Sets new @indent value.
  def outdent_token(move_out, no_newlines=nil, outdent_length=nil)
    decreased_indent = @indent - move_out
    while move_out > 0
      last_indent = @indents[-1]
      if !last_indent
        move_out = 0
      elsif last_indent == @outdebt
        move_out -= @outdebt
        @outdebt = 0
      elsif @outdebt > last_indent
        @outdebt -= last_indent
        move_out  -= last_indent
      else
        dent = @indents.pop + @outdebt
        if outdent_length && INDENTABLE_CLOSERS.include?(@chunk[outdent_length])
          decreased_indent -= dent - move_out
          move_out = dent
        end
        @outdebt = 0
        # pair might call outdent_token, so preserve decreased_indent
        pair(:OUTDENT)
        token(:OUTDENT, dent, 0, outdent_length)
        move_out -= dent
      end
    end
    @outdebt -= move_out if dent
    @tokens.pop while value == ';'

    token(:TERM, "\n", outdent_length, 0) unless tag == :TERM || no_newlines
    @indent = decreased_indent
  end

  # Matches and consumes non-meaningful whitespace. Tag the previous token
  # as being "spaced", because there are some cases where it makes a difference.
  def whitespace_token
    return if !(match = @chunk.match(WHITESPACE)) || (@chunk[0] == "\n")
    prev = @tokens[-1]
    prev.send(match ? :spaced= : :new_line=, true) if prev
    match ? match[0].size : 0
  end

  # Generate a newline token. Consecutive newlines get merged together.
  def newline_token(offset)
    @tokens.pop while value == ';'

    # 1. function prototype
    if tag == ':'
      indent_token(@indent+2)
      outdent_token(2)

    # 2. prevent doubles terminators
    # 3. prevent terminator after indent
    # 4. prevent starting with a term on an empty file
    elsif ![:TERM, :INDENT].include?(tag) && !tokens.empty?
      token(:TERM, "\n", offset, 0)
    end
  end

  # Use a `\` at a line-ending to suppress the newline.
  # The slash is removed here once its job is done.
  def suppress_newlines
    @tokens.pop if value[0] == ?\
  end

  # We treat all other single characters as a token. E.g.: `( ) , . !`
  # Multi-character operators are also literal tokens, so that Jison can assign
  # the proper order of operations. There are some symbols that we tag specially
  # here. `;` and newlines are both treated as a `TERM`, we distinguish
  # parentheses that indicate a method call from regular parentheses, and so on.
  def literal_token
    if match = @chunk.match(OPERATOR)
      value, _ = *match
    else
      value = @chunk[0]
    end
    tag = value

    if COMPOUND_ASSIGN.include?(value)
      tag = :COP
    else
      case value
      when '(', '{', '['   then @ends.push(INVERSES[value])
      when ')', '}', ']'
        prev = @tokens[-1]
        pair(value)
        tokens.delete_at(-1) if prev && prev[0] == :TERM
      end
    end
    token(tag, value)
    value.size
  end

  # Token Manipulators
  # ------------------

  # Sanitize a heredoc or herecomment by
  # erasing all external indentation on the left-hand side.
  def sanitize_heredoc(doc, options)
    indent, herecomment = options.values_at(:indent, :herecomment)
    if herecomment
      return doc unless doc.index_of("\n")
    elsif match = doc.match(HEREDOC_INDENT)
      attempt = match[1]
      indent = attempt  if indent.nil? || (attempt.size > 0 && indent.size > attempt.size)
    end
    doc = doc.gsub(/\n#{indent}/, "\n") if indent
    doc = doc.gsub(/\A\n/, '') unless herecomment
    doc
  end

  # Close up all remaining open blocks at the end of the file.
  def close_indentation!
    outdent_token(@indent)
  end

  # Matches a balanced group such as a single or double-quoted string. Pass in
  # a series of delimiters, all of which must be nested correctly within the
  # contents of the string. This method allows us to have strings within
  # interpolations within strings, ad infinitum.
  def balanced_string(str, end_str)
    continue_count = 0
    stack = [end_str]
    prev = ''
    (1...str.size).each do |i|
      if continue_count > 0
        continue_count -= 1
        next
      end
      case letter = str[i]
      when "\\"
        continue_count += 1
        next
      when end_str
        stack.pop
        return str[0..i] unless stack.size > 0
        end_str = stack[stack.size - 1]
        next
      end
      if end_str == '}' && ['"', "'"].include?(letter)
        stack.push(end_str = letter)
      elsif end_str == '}' && letter == '/' && (match = str[i..-1].match(HEREGEX)) || str[i..-1].match(REGEX)
        continue_count += match[0].size - 1
      elsif end_str == '}' && letter == '{'
        stack.push(end_str = '}')
      elsif end_str == '"' && prev == '#' && letter == '{'
        stack.push(end_str = '}')
      end
      prev = letter
    end
    raise_syntax_error! "missing #{stack.pop}, starting"
  end

  # Expand variables and expressions inside double-quoted strings using
  # Ruby-like notation for substitution of arbitrary expressions.
  #
  #     "Hello #{name.capitalize()}."
  #
  # If it encounters an interpolation, this method will recursively create a
  # new Lexer, tokenize the interpolated contents, and merge them into the
  # token stream.
  #
  #  - `str` is the start of the string contents (IE with the " or """ stripped
  #    off.)
  #  - `options.offset_in_chunk` is the start of the interpolated string in the
  #    current chunk, including the " or """, etc...  If not provided, this is
  #    assumed to be 0.  `options.lexed_length` is the length of the
  #    interpolated string, including both the start and end quotes.  Both of these
  #    values are ignored if `options.regex` is true.
  #  - `options.str_offset` is the offset of str, relative to the start of the
  #    current chunk.
  def interpolate_string(str, options = {})

    regex, offset_in_chunk, str_offset, lexed_length =
        options.values_at(:regex, :offset_in_chunk, :str_offset, :lexed_length)

    offset_in_chunk ||= 0
    str_offset ||= 0
    lexed_length ||= str.size
    error_token = nil

    # Parse the string.
    tokens = []
    pi = 0
    i  = -1
    while letter = str[i+=1]
      if letter == '\\'
        i += 1
        next
      end
      unless letter == '#' && str[i+1] == '{' &&
             (expr = balanced_string(str[i + 1..-1], '}'))
        next
      end
      # NEOSTRING is a fake token.  This will be converted to a string below.
      tokens.push(make_token(:NEOSTRING, str[pi...i], str_offset + pi)) if pi < i
      unless error_token
        error_token = make_token('', 'string interpolation', offset_in_chunk + i + 1, 2)
      end
      inner = expr[1...-1]
      if inner.size
        line, column = *get_line_and_column_from_chunk(str_offset + i + 1)
        nested = self.class.new(inner,
              line: line, column: column, rewrite: false).tokenize!
        popped = nested.pop
        popped = nested.shift if !nested.empty? && nested[0] == :TERM
        if len = nested.size
          if len > 1
            nested.unshift make_token('(', '(', str_offset + i + 1, 0)
            nested.push    make_token(')', ')', str_offset + i + 1 + inner.size, 0)
          end
          # Push a fake :TOKENS token, which will get turned into real tokens below.
          tokens.push [:TOKENS, nested]
        end
      end
      i += expr.size
      pi = i + 1
    end

    tokens.push make_token(:NEOSTRING, str[pi..-1], str_offset + pi) if i > pi && pi < str.size

    # If regex, then return now and let the regex code deal with all these fake tokens
    return tokens if regex

    # If we didn't find any tokens, then just return an empty string.
    return token(:STRING, '""', offset_in_chunk, lexed_length) unless tokens.size

    # If the first token is not a string, add a fake empty string to the beginning.
    tokens.unshift make_token(:NEOSTRING, '', offset_in_chunk) unless tokens[0][0] == :NEOSTRING

    if interpolated = tokens.size > 1
      token(:INTERPOLATION, '(', offset_in_chunk, 0, error_token)
    end

    # Push all the tokens
    tokens.each_with_index do |token, index|
      tag, value = *token
      if tag == :TOKENS
        # Push all the tokens in the fake :TOKENS token.  These already have
        # sane location data.
        @tokens.push(*value.to_a)
      elsif tag == :NEOSTRING
        # Convert NEOSTRING into STRING
        token[0] = :STRING
        token[1] = value
        @tokens.push(token)
      else
        raise_syntax_error! "Unexpected #{tag}"
      end
    end
    if interpolated
      rparen = make_token(')', ')', offset_in_chunk + lexed_length, 0)
      rparen.string_end = true
      @tokens.push(rparen)
    end
    tokens
  end

  # Pairs up a closing token, ensuring that all listed pairs of tokens are
  # correctly balanced throughout the course of the token stream.
  def pair(tag)
    wanted = @ends[-1]
    if tag != wanted
      raise_syntax_error! "unmatched #{tag} at #{@chunk}" if :OUTDENT != wanted
      # Auto-close INDENT to support syntax like this:
      #
      #     el.click((event) ->
      #       el.hide())
      #
      outdent_token(@indents[-1], true)
      return pair(tag)
    end
    @ends.pop
  end

  def pretty_print(colors=true)
    color = ->(tag) do
      return tag unless colors
      c =
        case tag
        when :INDENT     then 32
        when :OUTDENT    then 36
        when :TERM       then 35
        when :NAME       then 91
        else 31
        end
      "\e[#{c}m#{tag}\e[0m"
    end

    indent = 0
    i = -1
    out = StringIO.new

    while token = @tokens[i+=1]
      case token.tag
      when :INDENT
        out.puts
        out.print ' ' * (indent += token.value)
      when :OUTDENT
        out.puts
        out.print ' ' * (indent -= token.value)
      end

      out.print "[#{color[token.tag]} #{token.value.inspect}] "

      if %i[INDENT OUTDENT TERM].include?(token.tag)
        out.puts
        out.print ' ' * indent
      end
    end
    out.puts
    out.string
  end

  private
  # Helpers
  # -------

  # Returns the line and column number from an offset into the current chunk.
  #
  # `offset` == a number of characters into @chunk.
  def get_line_and_column_from_chunk(offset)
    if offset.zero?
      return [@chunk_line, @chunk_column]
    end

    string =
      offset >= @chunk.size ? @chunk : @chunk[0..offset-1]

    line_count = string.count("\n")

    column = @chunk_column
    if line_count > 0
      lines = string.split("\n")
      column = lines.empty? ? 0 : lines[-1].size
    else
      column += string.size
    end

    [@chunk_line + line_count, column]
  end

  # Same as "token", exception this just returns the token without adding it
  # to the results.
  def make_token(tag, value, offset_in_chunk=nil, length=nil)
    offset_in_chunk = 0 if offset_in_chunk.nil?
    length = value.to_s.size if length.nil? || length.zero?

    location_data = Location.new(*get_line_and_column_from_chunk(offset_in_chunk))

    # Use length - 1 for the final offset - we're supplying the last_line and the last_column,
    # so if last_column == first_column, then we're looking at a character of length 1.
    last_character = [0, length - 1].max

    location_data.last_line, location_data.last_column =
      get_line_and_column_from_chunk(offset_in_chunk + last_character)

    token = Token.new([tag, value])
    token.source = location_data
    token
  end

  def token(tag, value, offset_in_chunk=0, length=nil)
    token = make_token(tag, value, offset_in_chunk, length)
    @tokens.push token
    token
  end

  # Peek at a tag in the current token stream.
  def tag(index=-1, tag=nil)
    (tok = @tokens[index]) && (tag ? tok[0] = tag : tok[0])
  end

  # Peek at a value in the current token stream.
  def value(index=-1, val=nil)
    (tok = @tokens[index]) && (val ? tok[1] = val : tok[1])
  end

  # Are we in the midst of an unfinished expression?
  def unfinished
    unext = LINE_CONTINUER.match(@chunk) || UNFINISHED_EXPRESSIONS.include?(tag)
    return unext unless prev = @tokens[-1]
    uprev = prev[1].to_s.match(LINE_CONTINUER) || UNFINISHED_EXPRESSIONS.include?(prev[0])
    unext || uprev
  end

  def escape(string)
    string.gsub(/\n/, '\\n').gsub(/\t/, '\\t')
  end

  def raise_syntax_error!(message)
    line_column = get_line_and_column_from_chunk(0)
    message     = pretty_error_message(message, @code, line_column)
    raise SyntaxError, message, caller[1..-1]
  end
end
