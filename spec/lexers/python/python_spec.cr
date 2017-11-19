require "../../spec_helper"

require "../../../src/noir/lexers/python"

describe Noir::Lexers::Python do
  it "can find canonical name 'python'" do
    Noir.find_lexer("python").should be_a(Noir::Lexers::Python)
  end

  it "can find alias name 'py'" do
    Noir.find_lexer("py").should be_a(Noir::Lexers::Python)
  end

  it_lexes_fixtures "python", Noir::Lexers::Python
end
