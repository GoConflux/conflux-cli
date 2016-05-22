
module Conflux
  module CLI

    def self.start!(*args)
      # Setup StdIn/StdOut sync
      $stdin.sync = true if $stdin.isatty
      $stdout.sync = true if $stdout.isatty

      # Strip out command
      command = args.shift.strip rescue "help"

      # only load up cli if it makes it to this point
      require 'conflux/command'

      # Load up all commands
      Conflux::Command.load

      # Run command
      Conflux::Command.run(command, args)

    rescue Errno::EPIPE => e
      puts(e.message)

    rescue Interrupt => e
      puts("Command cancelled.", false)

    rescue => error
      puts(error)
      exit(1)
    end

  end
end