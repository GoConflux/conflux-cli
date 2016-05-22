
module Conflux
  module Helpers

    extend self

    def error(message, report = false)
      # if Conflux::Helpers.error_with_failure
      #   display("failed")
      #   Conflux::Helpers.error_with_failure = false
      # end
      #
      # $stderr.puts(format_with_bang(message))
      # rollbar_id = Rollbar.error(message) if report
      # $stderr.puts("Error ID: #{rollbar_id}") if rollbar_id

      puts message
      exit(1)
    end

    def display(msg = '', new_line = true)
      new_line ? puts(msg) : print(msg)
      $stdout.flush
    end

  end
end