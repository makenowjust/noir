require "../formatter"
require "../theme"

class Noir::Formatters::TerminalRGB < Noir::Formatter
  def initialize(@theme : Theme, @out : IO)
  end

  def format(token, value) : Nil
    if token
      style = @theme.style_for token
    else
      style = @theme.base_style
    end

    value.each_line(chomp: false) do |line|
      wrote = false

      if c = style.fore
        @out << "\e[" unless wrote
        @out << "38;2;#{c.red};#{c.green};#{c.blue}"
        wrote = true
      end

      if style.bold
        @out << "\e[" unless wrote
        @out << ";" if wrote
        @out << "1"
        wrote = true
      end

      if style.italic
        @out << "\e[" unless wrote
        @out << ";" if wrote
        @out << "3"
        wrote = true
      end

      if style.underline
        @out << "\e[" unless wrote
        @out << ";" if wrote
        @out << "4"
        wrote = true
      end

      @out << "m" if wrote
      @out << line.chomp
      @out << "\e[0m" if wrote
      @out.puts if line.ends_with?("\n")
    end
  end
end
