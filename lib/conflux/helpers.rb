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

  end
end