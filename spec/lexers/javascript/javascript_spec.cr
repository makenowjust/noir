require "../../spec_helper"

require "../../../src/noir/lexers/javascript"

describe Noir::Lexers::JavaScript do
  it "can find canonical name 'javascript'" do
    Noir.find_lexer("javascript").should be_a(Noir::Lexers::JavaScript)
  end

  it "can find alias name 'js'" do
    Noir.find_lexer("js").should be_a(Noir::Lexers::JavaScript)
  end

  it_lexes_fixtures "javascript", Noir::Lexers::JavaScript
end
