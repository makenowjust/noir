require "./lexer"

module Noir::Lexers
  LEXERS = {} of String => Lexer.class

  def self.register(name : String, klass)
    LEXERS[name] = klass
  end

  def self.find(name : String) : Lexer?
    LEXERS[name]?.try &.new
  end
end
