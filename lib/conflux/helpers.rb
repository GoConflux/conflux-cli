require 'open3'

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

    def prompt_user_to_select_app(apps_map)
      answer = nil
      question = "\nWhich Conflux app does this project belong to?\n"

      until !answer.nil?
        count = 0
        app_slugs = []

        puts question

        apps_map.each { |team, apps|
          puts "\n#{team}:\n\n"

          apps.each { |slug|
            count += 1
            puts "(#{count}) #{slug}"
            app_slugs << slug
          }
        }

        puts "\n"

        response = allow_user_response

        if app_slugs.include?(response)
          answer = response
        else
          response_int = response.to_i rescue 0

          if response_int > 0
            answer = app_slugs[response_int - 1]
          end
        end

        question = "\nSorry I didn't catch that. Can you respond with the number that appears next to your answer?"
      end

      answer
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

    def is_rails_project?
      File.exists?(File.join(Dir.pwd, 'Gemfile'))
    end

    def is_node_project?
      File.exists?(File.join(Dir.pwd, 'package.json'))
    end

    def install_conflux_gem
      display('Installing conflux ruby gem...')

      # returns array of [stdout, stderr, status]
      normal_install = Open3.capture3('gem install conflux')
      errors = normal_install[1]

      # If error exist
      if !errors.empty?
        if errors.match(/Gem::FilePermissionError/)
          display('Got permission error...trying again with sudo.')
          system('sudo gem install conflux')
        else
          puts errors
        end
      end
    end

    def gem_exists?
      capture = Open3.capture3('gem which conflux')

      begin
        !capture[0].empty? && capture[1].empty? && capture[2].exitstatus == 0
      rescue
        false
      end
    end

    def manually_added_methods(klass)
      klass.instance_methods(false)
    end

  end
end