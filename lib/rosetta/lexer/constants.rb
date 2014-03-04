module Rosetta
  class Lexer
    module Constants

      TOKENS = Hash[
        'int8',         :NAME,
        'int16',        :NAME,
        'int32',        :NAME,
        'int64',        :NAME,

        'uint8',        :NAME,
        'uint16',       :NAME,
        'uint32',       :NAME,
        'uint64',       :NAME,

        'float32',      :NAME,
        'float64',      :NAME,

        'complex64',    :NAME,
        'complex128',   :NAME,

        'bool',         :NAME,
        'string',       :NAME,

        'any',          :NAME,

        'break',        :BREAK,
        'case',         :CASE,
        'chan',         :CHAN,
        'const',        :CONST,
        'continue',     :CONTINUE,
        'default',      :DEFAULT,
        'else',         :ELSE,
        'defer',        :DEFER,
        'fallthrough',  :FALL,
        'for',          :FOR,

        # Function handling
        'def',          :DEF,
        'do',           :DO,
        'func',         :FUNC,

        'go',           :GO,
        'goto',         :GOTO,
        'if',           :IF,
        'import',       :IMPORT,
        'interface',    :INTERFACE,
        'map',          :MAP,
        'package',      :PACKAGE,
        'range',        :RANGE,
        'return',       :RETURN,
        'select',       :SELECT,
        'struct',       :STRUCT,
        'switch',       :SWITCH,
        'type',         :TYPE,
        'var',          :VAR,
        'const',        :CONST,

        'class',        :CLASS,
        'module',       :MODULE,

        'append',       :NAME,
        'cap',          :NAME,
        'close',        :NAME,
        'complex',      :NAME,
        'copy',         :NAME,
        'delete',       :NAME,
        'imag',         :NAME,
        'len',          :NAME,
        'make',         :NAME,
        'new',          :NAME,
        'panic',        :NAME,
        'print',        :NAME,
        'println',      :NAME,
        'real',         :NAME,
        'recover',      :NAME,

        'notwithstanding',       :IGNORE,
        'thetruthofthematter',   :IGNORE,
        'despiteallobjections',  :IGNORE,
        'whereas',               :IGNORE,
        'insofaras',             :IGNORE
      ]

      COMMENT = /\A *# ?(.*)/

      IDENTIFIER = /\A
        ( [$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]* )
      /x

      WHITESPACE = /\A[^\n\S]+/
      TRAILING_SPACES = /\s+\z/

      # The character code of the nasty Microsoft madness otherwise known as the BOM.
      BOM = 65279

      LINE_BREAK = [:INDENT, :OUTDENT, :TERM]

      UNFINISHED_EXPRESSIONS = [
        '\\', '.',
        # COMPARE
        '==', '!=', '<', '>', '<=', '>=',
        # LOGIC
        '&&', '||', '&', '|', '^'
      ]

      FORBIDDEN = [] # identifiers that you can't never use
      RESERVED  = [] # identifiers you can use but not assign

      ALIASES = {
        and: '&&',
        or: '||',
        is: '==',
        isnt: '!=',
        not: '!'
      }

      TARGET_KEYWORDS = %w[]

      NUMBER = /
        \A 0b[01]+    |              # binary
        \A 0o[0-7]+   |              # octal
        \A 0x[\da-f]+ |              # hex
        \A \d*\.?\d+ (?:e[+-]?\d+)?  # decimal
      /xi

      OPERATOR = / \A
        (?: ->                # return values
          | [-+*\/%<>&|^!?=]= # compound assign | compare
          | ([-+:])\1         # doubles
          | :=                # short variable declaration
          | <-                # not really an operator but a chan
          | ([&|<>])\2=?      # logic | shift
          | \.{2,3}           # range or splat
      ) /x

      # Compound assignment tokens.
      COMPOUND_ASSIGN = [
        '+=', '&=',  '-=', '|=',  '*=', '^=',
        '/=', '<<=', '%=', '>>=', '&^', '&^=',
        '||='
      ]

      MULTI_DENT = /\A(?:\n[^\n\S]*)/
      HEREDOC    = /\A("""|''') ((?: \\[\s\S] | [^\\] )*?) (?:\n[^\n\S]*)? \1 /x
      SIMPLESTR  = /\A'[^\\']*(?:\\[\s\S][^\\']*)*'/

      # Regex-matching-regexes.
      REGEX = %r~ \A
        (/ (?! [\s=] )   # disallow leading whitespace or equals signs
        [^\[/\n\\]*  # every other thing
        (?:
          (?: \\[\s\S]   # anything escaped
            | \[         # character class
                [^\]\n\\]*
                (?: \\[\s\S] [^\]\n\\]*)*
              \]
          ) [^\[/\n\\]*
        )*
        /) ([imgy]{0,4}) (?!\w)
      ~x
      HEREGEX = /\A \/{3} ((?:\\?[\s\S])+?) \/{3} ([imgy]{0,4}) (?!\w) /x
      HEREGEX_OMIT = %r~
          ((?:\\\\)+)     # consume (and preserve) an even number of backslashes
        | \\(\s|/)        # preserve escaped whitespace and "de-escape" slashes
        | \s+(?:\#.*)?    # remove whitespace and comments
      ~x
      NOT_REGEX = [:NUMBER, :REGEX, :BOOL, :NULL, '++', '--']
      NOT_SPACED_REGEX = NOT_REGEX.concat [')', '}', :NAME, :STRING, ']']

      MULTILINER      = /\n/
      HEREDOC_INDENT  = /\n+([^\n\S]*)/
      HEREDOC_ILLEGAL = /\*\//
      LINE_CONTINUER  = /\A\s*(?:,|\.(?![.\s\d]))/

      # Additional indent in front of these is ignored.
      INDENTABLE_CLOSERS = [')', '}', ']']

      # List of the token pairs that must be balanced.
      BALANCED_PAIRS = [
        ['(', ')'],
        ['[', ']'],
        ['{', '}'],
        [:INDENT, :OUTDENT]
      ]

      # The inverse mappings of `BALANCED_PAIRS` we're trying to fix up, so we can
      # look things up from either end.
      INVERSES = {}

      # The tokens that signal the start/end of a balanced pair.
      EXPRESSION_START = []
      EXPRESSION_END   = []

      BALANCED_PAIRS.each do |left, rite|
        EXPRESSION_START.push INVERSES[rite] = left
        EXPRESSION_END.push   INVERSES[left] = rite
      end
    end
  end
end
