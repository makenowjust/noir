require "html"

require "../formatter"
require "../theme"

class Noir::Formatters::HTML < Noir::Formatter
  def initialize(@out : IO)
  end

  def format(token, value) : Nil
    if token && token != Tokens::Text
      klass = token.short_name
      @out << %(<span class="#{klass}">)
      ::HTML.escape value, @out
      @out << %(</span>)
    else
      ::HTML.escape value, @out
    end
  end
end
