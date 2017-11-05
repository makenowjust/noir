# `Noir` is a syntax highlight library for Crystal.
module Noir
end

require "./noir/formatter"
require "./noir/formatters"
require "./noir/lexer"
require "./noir/lexers"
require "./noir/theme"
require "./noir/themes"
require "./noir/version"

module Noir
  def self.find_lexer(name : String) : Lexer?
    Lexers.find(name)
  end

  def self.find_theme(name : String, scope = ".highlight") : Theme?
    Themes.find(name, scope: scope)
  end

  def self.highlight(code : String, lexer, formatter)
    lexer.lex_all code, formatter
  end
end
