require "../../spec_helper"

require "../../../src/noir/lexers/crystal"

describe Noir::Lexers::Crystal do
  it "can find canonical name 'crystal'" do
    Noir.find_lexer("crystal").should be_a(Noir::Lexers::Crystal)
  end

  it "can find alias name 'cr'" do
    Noir.find_lexer("cr").should be_a(Noir::Lexers::Crystal)
  end

  it_lexes_fixtures "crystal", Noir::Lexers::Crystal
end
