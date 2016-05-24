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
      return message if !message.is_a?(String)
      return '' if message.to_s.strip == ''

      " !    " + message.encode('utf-8', 'binary', invalid: :replace, undef: :replace)
                   .split("\n")
                   .join("\n !    ")
    end

    def camelize(str)
      str.split('_').collect(&:capitalize).join
    end

    def ask_free_response_question(question, answer_prefix = '')
      puts question
      print answer_prefix
      response = allow_user_response
      response
    end

    def ask_mult_choice_question(question, answers)
      answer = nil

      until !answer.nil? && answer.is_a?(Integer)
        puts question
        answers.each_with_index { |answer, i| puts "(#{i + 1}) #{answer}" }
        puts ''

        response = allow_user_response

        answer = answers.index(response) if answers.include?(response) rescue nil
        answer = (response.to_i - 1) if !answers[response.to_i - 1].nil? rescue nil

        question = 'Sorry I didn\'t catch that. Can you respond with the number that appears next to your answer?'
      end

      answer
    end

    def allow_user_response
      $stdin.gets.to_s.strip
    end

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def running_on_a_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end

    def with_tty(&block)
      return unless $stdin.isatty
      begin
        yield
      rescue
        # fails on windows
      end
    end

    def home_directory
      if running_on_windows?
        # This used to be File.expand_path("~"), which should have worked but there was a bug
        # when a user has a cyrillic character in their username.  Their username gets mangled
        # by a C code operation that does not respect multibyte characters
        #
        # see: https://github.com/ruby/ruby/blob/v2_2_3/win32/file.c#L47
        home = Conflux::Helpers::Env['HOME']
        homedrive = Conflux::Helpers::Env['HOMEDRIVE']
        homepath = Conflux::Helpers::Env['HOMEPATH']
        userprofile = Conflux::Helpers::Env['USERPROFILE']

        home_dir = if home
                     home
                   elsif homedrive && homepath
                     homedrive + homepath
                   elsif userprofile
                     userprofile
                   else
                     # The expanding `~' error here does not make much sense
                     # just made it match File.expand_path when no env set
                     raise ArgumentError.new("couldn't find HOME environment -- expanding `~'")
                   end

        home_dir.gsub(/\\/, '/')
      else
        Dir.home
      end
    end

    def host
      host_url.gsub(/http:\/\/|https:\/\//, '')
    end

    def host_url
      ENV['CONFLUX_HOST'] || 'http://api.goconflux.com'
    end

  end
end