require "html"

require "../formatter"
require "../theme"

class Noir::Formatters::HTMLInline < Noir::Formatter
  def initialize(@theme : Theme, @out : IO)
  end

  def format(token, value) : Nil
    if token && token != Tokens::Text
      style = @theme.style_for(token)
      @out << %(<span style="#{style}">)
      ::HTML.escape value, @out
      @out << %(</span>)
    else
      ::HTML.escape value, @out
    end
  end
end
