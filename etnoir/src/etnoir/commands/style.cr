require "option_parser"

require "noir"

require "../themes"

module Etnoir::Commands::Style
  @out : IO

  abstract def raise(message)
  abstract def exit(status)

  def style(args)
    option = parse_style_option(args)

    option.theme.to_s @out
  end

  record Option,
    theme : Noir::Theme

  def parse_style_option(args)
    theme = nil
    scope = ".highlight"

    OptionParser.parse(args) do |parser|
      parser.banner = <<-BANNER
      ET NOIR - NOIR command-line tool

      Usage: etnoir style [-s SCOPE] THEME

      Option:
      BANNER

      parser.on("-s SCOPE", "--scope=SCOPE", "specify the scope to apply theme CSS (default: .highlight)") do |selector|
        scope = selector
      end

      parser.on("-h", "--help", "show this help") do
        puts parser
        exit 0
      end

      parser.unknown_args do |ar, gs|
        args = ar + gs
        raise "THEME is not specified" if args.empty?
        raise "multiple THEMEs are not allowed" if args.size >= 2

        name = args.first
        unless theme = Noir.find_theme(name, scope: scope)
          raise "unknown theme '#{name}'"
        end
      end
    end

    Option.new(theme.not_nil!)
  end
end
