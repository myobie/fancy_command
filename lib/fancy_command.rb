require "fancy_command/version"
require "fancy_command/command"

module FancyCommand
  def self.new(string, **opts, &blk)
    Command.new(string, **opts, &blk)
  end

  def run(string, **opts, &blk)
    command(string, **opts, &blk).()
  end

  def command(string, **opts, &blk)
    Command.new(string, **opts, &blk)
  end
end
