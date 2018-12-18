require "../../spec_helper"

require "../../../src/noir/lexers/html"

describe Noir::Lexers::HTML do
  it "can find canonical name 'html'" do
    Noir.find_lexer("html").should be_a(Noir::Lexers::HTML)
  end

  it_lexes_fixtures "html", Noir::Lexers::HTML
end
