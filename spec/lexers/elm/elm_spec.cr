require "../../spec_helper"

require "../../../src/noir/lexers/elm"

describe Noir::Lexers::Elm do
  it "can find canonical name 'elm'" do
    Noir.find_lexer("elm").should be_a(Noir::Lexers::Elm)
  end

  it_lexes_fixtures "elm", Noir::Lexers::Elm
end
