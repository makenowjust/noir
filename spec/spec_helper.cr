require "spec"

require "../src/noir"

UPDATE_FIXTURE = ENV["UPDATE_FIXTURE"]? == "1"

class SpecFormatter < Noir::Formatter
  @out : IO::Memory

  def initialize
    @out = IO::Memory.new
  end

  def format(token, value): Nil
    [token, value].inspect @out
    @out.puts
  end

  def to_s(io)
    @out.to_s io
  end
end

def it_lexes_fixtures(name, lexer_class, dir = __DIR__)
  Dir.glob("#{dir}/fixtures/*.in") do |in_file|
    in_text = File.read(in_file)

    out_file = in_file.gsub(/\.in$/, ".out")
    if File.exists?(out_file) && !UPDATE_FIXTURE
      out_text = File.read(out_file)
    elsif !UPDATE_FIXTURE
      raise "cannot find output file against '#{in_file}'"
    end

    lexer = lexer_class.new
    formatter = SpecFormatter.new

    Noir.highlight(in_text, lexer: lexer, formatter: formatter)
    if out_text
      it "should highlight #{in_text.inspect} to #{out_text.inspect}" do
        formatter.to_s.should eq(out_text)
      end
    else
      File.write(out_file, formatter.to_s)
    end
  end
end
