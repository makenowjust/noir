require "./error"
require "./exit"
require "./commands/*"

class Etnoir::Command
  include Commands::Highlight
  include Commands::Style

  HELP = <<-HELP
  ET NOIR - NOIR command-line tool

  Usage:
      etnoir highlight FILENAME
      etnoir style THEME

  Command:
      highlight                        highlight FILENAME content
      style                            print THEME style as CSS
      help                             show this help
      version                          show ET NOIR version
  HELP

  def initialize(@out : IO)
  end

  def run(args = ARGV.dup)
    case command = args.shift?
    when .nil?, "help", "-h", "--help"
      @out.puts HELP
    when "version", "-v", "--version"
      @out.puts Noir::VERSION
    when "highlight"
      highlight args
    when "style"
      style args
    else
      raise "unknown command '#{command}'"
    end
  end

  def raise(message)
    ::raise Error.new(message)
  end

  def exit(status)
    ::raise Exit.new(status)
  end
end
