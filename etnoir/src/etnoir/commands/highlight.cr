require "option_parser"

require "noir"

require "../formatters"
require "../lexers"
require "../themes"

module Etnoir::Commands::Highlight
  @out : IO

  abstract def raise(message)
  abstract def exit(status)

  def highlight(args)
    option = parse_highlight_option(args)

    code = File.read option.filename
    Noir.highlight code,
      lexer: option.lexer,
      formatter: option.formatter
  end

  record Option,
    filename : String,
    lexer : Noir::Lexer,
    formatter : Noir::Formatter

  def parse_highlight_option(args)
    filename = nil
    lexer = nil
    theme = Noir.find_theme(DEFAULT_THEME).not_nil!
    formatter = DEFAULT_FORMATTER

    OptionParser.parse(args) do |parser|
      parser.banner = <<-BANNER
      ET NOIR - NOIR command-line tool

      Usage: etnoir highlight [-l LEXER] [-t THEME] [-f FORMATTER] FILENAME

      Option:
      BANNER

      parser.on("-l LEXER", "--lexer=LEXER", "specify the lexer to use") do |name|
        unless lexer = Noir.find_lexer(name)
          raise "unknown lexer '#{name}'"
        end
      end

      parser.on("-t THEME", "--theme=THEME", "specify the theme to use for highlighting (default: #{DEFAULT_THEME}") do |name|
        unless theme = Noir.find_theme(name)
          raise "unknown theme '#{name}'"
        end
      end

      parser.on("-f FORMATTER", "--formatter=FORMATTER", "specify the output formatter to use (default: #{DEFAULT_FORMATTER})") do |name|
        unless Formatters.valid_name?(name)
          raise "unknown formatter '#{name}'"
        end
      end

      parser.on("-h", "--help", "show this help") do
        puts parser
        exit 0
      end

      parser.unknown_args do |ar, gs|
        args = ar + gs
        raise "FILENAME is not specified" if args.empty?
        raise "multiple FILENAMEs are not allowed" if args.size >= 2

        filename = args.first
      end
    end

    # TODO: should use Lexer#.filenames, but Crystal doesn't have `File#fnmatch` currently. It uses filename extension as lexer name for now.
    # See https://github.com/crystal-lang/crystal/pull/5179
    if !lexer && /\.(\w+)\z/ =~ filename
      ext = $1
      lexer = Noir.find_lexer ext
    end

    raise "LEXER is not specified" unless lexer

    Option.new filename.not_nil!,
      lexer: lexer.not_nil!,
      formatter: Formatters.instantiate(formatter, theme.not_nil!, @out)
  end
end
