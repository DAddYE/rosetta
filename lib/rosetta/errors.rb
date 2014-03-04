module Rosetta

  module ErrorHelper
    def pretty_error_message(message, code, location, filename=nil)
      first_line, first_column, last_line, last_column =
        location.is_a?(Rosetta::Lexer::Location) ? location.to_a : location

      first_column  = 0 if first_column.nil?
      last_line   ||= first_line
      last_column ||= first_column
      filename    ||= '[stdin]'

      code_line  = code.split("\n")[first_line]
      starting   = first_column # first_column > 0 ? first_column - 1 : 0
      ending     = first_line == last_line ? last_column + 1 : code_line.size
      marker     = (starting > 0 ? ' ' * starting : '') << ('^' * (ending - starting))
      colorize   = ->(str) { "\e[1;31m#{str}\e[0m" }
      code_line  = code_line[0...starting] << colorize[code_line[starting...ending]] <<
        code_line[ending..-1].to_s
      marker     = colorize[marker]

      [].tap do |m|
        m << "#{filename}:#{first_line + 1}:#{first_column + 1} Error: #{message}"
        m << code.lines[first_line-1] unless first_line == 0
        m << code_line
        m << marker
        m << code.lines[first_line+1] unless first_line >= code.lines.size
      end.
      compact.
      map(&:chomp).
      join("\n")
    end
  end

  class SyntaxError < RuntimeError; end
  class ParseError < RuntimeError

    include Rosetta::ErrorHelper

    TOKEN_MAP = {
      'INDENT'  => 'indent',
      'OUTDENT' => 'outdent',
      "\n"      => 'newline'
    }

    def initialize(*args)
      @token, @token_id, @value, @lexer, @stack, @message = *args
    end

    def message
      msg =
        if @token
          code      = @lexer.code
          line      = @token.source.first_line
          line_part = "line #{line}:"
          id_part   = @token_id != @value.to_s ? " unexpected #{@token_id.to_s.downcase}" : ""
          val_part  = @message || "for #{TOKEN_MAP[@value.to_s] || "'#{@value}'"}"
          message   = "#{line_part} syntax error, #{val_part}#{id_part} analyzing"
          pretty_error_message(message, code, line)
        else
          id_part = @token_id != @value.to_s ? " unexpected #{@token_id.to_s.downcase}" : ""
          val_part = @message || "for #{TOKEN_MAP[@value.to_s] || "'#{@value}'"}"
          "syntax error, #{val_part}#{id_part} analyzing"
        end
      msg = "#{msg}\n#{@lexer.pretty_print}" if ENV['DEBUG']
      msg
    end
    alias_method :inspect, :message
  end
end
