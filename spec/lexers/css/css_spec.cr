require "../../spec_helper"

require "../../../src/noir/lexers/css"

describe Noir::Lexers::CSS do
  it "can find canonical name 'css'" do
    Noir.find_lexer("css").should be_a(Noir::Lexers::CSS)
  end

  it_lexes_fixtures "css", Noir::Lexers::CSS
end
