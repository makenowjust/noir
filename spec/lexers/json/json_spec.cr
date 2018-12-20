require "../../spec_helper"

require "../../../src/noir/lexers/json"

describe Noir::Lexers::JSON do
  it "can find canonical name 'json'" do
    Noir.find_lexer("json").should be_a(Noir::Lexers::JSON)
  end

  it_lexes_fixtures "json", Noir::Lexers::JSON
end
