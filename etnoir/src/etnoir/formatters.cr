module Etnoir
  module Formatters
    FORMATTERS = {
      "html", "html-inline",
      "terminal-rgb",
    }

    def self.valid_name?(name)
      FORMATTERS.includes? name
    end

    def self.instantiate(name, theme, io)
      case name
      when "html"
        Noir::Formatters::HTML.new io
      when "html-inline"
        Noir::Formatters::HTMLInline.new theme, io
      when "terminal-rgb"
        Noir::Formatters::TerminalRGB.new theme, io
      else
        raise "unknown formatter '#{name}'"
      end
    end
  end

  DEFAULT_FORMATTER = "terminal-rgb"
end
