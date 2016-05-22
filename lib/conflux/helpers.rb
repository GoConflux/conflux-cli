module Conflux
  module Helpers
    extend self

    def error(msg = '')
      $stderr.puts(format_with_bang(msg))
      exit(1)
    end

    def display(msg = '')
      puts(msg)
      $stdout.flush
    end

    def format_with_bang(message)
      return '' if message.to_s.strip == ''
      " !    " + message.encode('utf-8', 'binary', invalid: :replace, undef: :replace)
                     .split("\n")
                     .join("\n !    ")
    end

    def camelize(str)
      str.split('_').collect(&:capitalize).join
    end

  end
end