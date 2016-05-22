require 'conflux/helpers'

module Conflux
  module Command
    class CommandFailed < RuntimeError; end

    extend Conflux::Helpers

    def self.load
      # Require all the command files
      Dir[File.join(File.dirname(__FILE__), 'command', '*.rb')].each do |file|
        require file
      end
    end

    def self.run(cmd, arguments = [])
      puts "Command: #{cmd}  Arguments: #{arguments}"
      return
    end

  end
end