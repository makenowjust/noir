require "../../spec_helper"

require "../../../src/noir/lexers/yaml"

describe Noir::Lexers::YAML do
  it "can find canonical name 'yaml'" do
    Noir.find_lexer("yaml").should be_a(Noir::Lexers::YAML)
  end

  it_lexes_fixtures "yaml", Noir::Lexers::YAML
end

