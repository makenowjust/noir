# :nodoc:
class Noir::Scanner
  getter reader : Char::Reader

  def initialize(string : String)
    @reader = Char::Reader.new string
  end

  def scan(re : Regex) : Regex::MatchData?
    if m = re.match_at_byte_index(reader.string, reader.pos, Regex::Options::ANCHORED)
      @reader.pos = m.byte_end 0
      m
    end
  end

  def has_next?
    reader.has_next?
  end

  def current_char
    reader.current_char
  end

  def next_char
    reader.next_char
  end
end
