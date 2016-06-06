require 'conflux/helpers'

module Conflux
  module CLI
    extend Conflux::Helpers

    def self.start!(*args)
      # Setup StdIn/StdOut sync
      $stdin.sync = true if $stdin.isatty
      $stdout.sync = true if $stdout.isatty

      # Strip out command
      command = args.shift.strip rescue 'help'

      require 'conflux/command'

      ENV['CONFLUX_HOST'] = 'http://localhost:5000'

      Conflux::Command.find_command(command, args)
    rescue Errno::EPIPE => e
      error(e.message)
    rescue Interrupt => e
      error('Command cancelled.')
    rescue => e
      error(e)
    end

  end
end