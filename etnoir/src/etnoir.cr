require "colorize"

module Etnoir
end

require "./etnoir/command"
require "./etnoir/error"
require "./etnoir/exit"

begin
  Etnoir::Command.new(STDOUT).run
  exit 0
rescue e : Etnoir::Exit
  exit e.status
rescue e : Etnoir::Error
  STDERR.print "ERROR: ".colorize(:red)
  STDERR.puts e.message.colorize.bold
  exit 1
end
