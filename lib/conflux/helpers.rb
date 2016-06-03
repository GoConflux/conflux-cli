require_relative './auth'

module Conflux
  module Helpers
    extend self

    def ensure_authed
      @credentials = Conflux::Auth.read_credentials

      if @credentials.nil?
        error("Permission Denied. Run `conflux login` to login to your Conflux account.")
      end

      @email = @credentials[0]
      @password = @credentials[1]
    end

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

    def reply_no_conflux_app
      display "Directory not currently connected to a conflux app.\n"\
      "Run \"conflux init\" to a establish a connection with one of your apps."
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

    def manually_added_methods(klass)
      klass.instance_methods(false)
    end

    def conflux_folder_path
      "#{Dir.pwd}/.conflux/"
    end

    def conflux_manifest_path
      File.join(conflux_folder_path, 'manifest.json')
    end

    def conflux_jobs_path
      File.join(conflux_folder_path, 'jobs.txt')
    end

    def conflux_yml_path
      File.join(conflux_folder_path, 'conflux.yml')
    end

    def past_jobs
      File.exists?(conflux_jobs_path) ? File.read(conflux_jobs_path).split(',').map(&:strip) : []
    end

    def gemfile
      File.join(Dir.pwd, 'Gemfile')
    end

    def s3_url
      ENV['CONFLUX_S3_URL'] || 'http://confluxapp.s3-website-us-west-1.amazonaws.com'
    end

  end
end