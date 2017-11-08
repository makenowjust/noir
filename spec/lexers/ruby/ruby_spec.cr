require "../../spec_helper"

require "../../../src/noir/lexers/ruby"

describe Noir::Lexers::Ruby do
  it "can find canonical name 'ruby'" do
    Noir.find_lexer("ruby").should be_a(Noir::Lexers::Ruby)
  end

  it "can find alias name 'rb'" do
    Noir.find_lexer("rb").should be_a(Noir::Lexers::Ruby)
  end

  it_lexes_fixtures "ruby", Noir::Lexers::Ruby
end
