require_relative './auth'
require 'open3'

module Conflux
  module Helpers
    extend self

    # ensure a conflux user is authed (ensure creds exist in .netrc file)
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

    # Add a bang to an error message
    def format_with_bang(message)
      return message if !message.is_a?(String)
      return '' if message.to_s.strip == ''

      " !    " + message.encode('utf-8', 'binary', invalid: :replace, undef: :replace)
                   .split("\n")
                   .join("\n !    ")
    end

    def display(msg = '')
      puts(msg)
      $stdout.flush
    end

    # Called if user tries to run a command that relies on there being a conflux bundle connected
    # to the user's current working directory.
    def reply_no_conflux_app
      display "Directory not currently connected to a conflux bundle.\n"\
      "Run \"conflux init\" to a establish a connection with one of your bundles."

      exit(0)
    end

    # convert string from underscores to camelcase
    def camelize(str)
      str.split('_').collect(&:capitalize).join
    end

    # format some data into a table to then be displayed to the user
    def to_table(data, headers)
      column_lengths = []
      gutter = 2
      table = ''

      # Figure out column widths based on longest string in each column (including the header string)
      headers.each { |header|
        width = data.map { |_| _[header] }.max_by(&:length).length

        width = header.length if width < header.length

        column_lengths << width
      }

      # format the length of a table cell string to make it as wide as the column (by adding extra spaces)
      format_row_entry = lambda { |entry, i|
        entry + (' ' * (column_lengths[i] - entry.length + gutter))
      }

      # Add headers
      headers.each_with_index { |header, i|
        table += format_row_entry.call(header, i)
      }

      table += "\n"

      # Add line breaks under headers
      column_lengths.each { |length|
        table += (('-' * length) + (' ' * gutter))
      }

      table += "\n"

      # Add rows
      data.each { |row|
        headers.each_with_index { |header, i|
          table += format_row_entry.call(row[header], i)
        }

        table += "\n"
      }

      table
    end

    # Called during `conflux init` so that the user can choose which conflux bundle
    # to connect with his current working directory.
    def prompt_user_to_select_app(apps_map)
      answer = nil
      question = "\nWhich Conflux bundle do you wish to use for this project?\n"

      # Keep asking until the user responds with one of the possible answers
      until !answer.nil?
        count = 0
        app_slugs = []

        puts question

        apps_map.each { |team, apps|
          puts "\n#{team}:\n\n"   # separate apps out by team for easier selection

          apps.each { |slug|
            count += 1
            puts "(#{count}) #{slug}"
            app_slugs << slug
          }
        }

        puts "\n"

        response = allow_user_response

        # it's fine if the user responds with an exact app slug
        if app_slugs.include?(response)
          answer = response

        # otherwise, they can just respond with the number next to the app they wish to choose
        else
          response_int = response.to_i rescue 0
          answer = app_slugs[response_int - 1 ]if response_int > 0
        end

        question = "\nSorry I didn't catch that. Can you respond with the number that appears next to your answer?"
      end

      answer
    end

    # Ask a free response question with a optional prefix (prefix example --> 'Password: ')
    def ask_free_response_question(question, answer_prefix = '')
      puts question
      print answer_prefix
      response = allow_user_response
      response
    end

    # Ask a multiple choice question, with numbered answers
    def ask_mult_choice_question(question, answers)
      answer = nil

      # Prompt will continue until user has responded with one of the numbers next to an answer
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

    # Get one of two sets of headers for an AJAX request based on a passed in bool.
    def conditional_headers(use_manifest_creds)
      # If boolean is true, use the credentials listed inside .conflux/manifest.json
      # for your set of headers
      if use_manifest_creds
        if File.exists?(conflux_manifest_path)
          manifest = JSON.parse(File.read(conflux_manifest_path)) rescue {}

          @manifest_creds = manifest['configs'] || {}

          if !@manifest_creds.key?('CONFLUX_USER') || !@manifest_creds.key?('CONFLUX_APP')
            reply_no_conflux_app
          end

          headers = manifest_headers
        else
          reply_no_conflux_app
        end

      # Otherwise, default to using the user's conflux password stored in .netrc file.
      # Ensure user is authed first though.
      else
        ensure_authed
        headers = netrc_headers
      end

      headers
    end

    def manifest_headers
      {
        'Conflux-User' => @manifest_creds['CONFLUX_USER'],
        'Conflux-App' => @manifest_creds['CONFLUX_APP']
      }
    end

    def netrc_headers
      @password ? { 'Conflux-User' => @password } : {}
    end

    # Strip the protocol + following slashes off of a url
    def host
      host_url.gsub(/http:\/\/|https:\/\//, '')
    end

    def host_url
      ENV['CONFLUX_HOST'] || 'https://api.goconflux.com'
    end

    def is_rails_project?
      File.exists?(File.join(Dir.pwd, 'Gemfile'))
    end

    def is_node_project?
      File.exists?(File.join(Dir.pwd, 'package.json'))
    end

    # Get an array (of symbols) of the user-defined methods for a klass
    def manually_added_methods(klass)
      klass.instance_methods(false)
    end

    # Path for the git-ignored folder that holds all info tying a directory to a specific conflux bundle
    def conflux_folder_path
      "#{Dir.pwd}/.conflux/"
    end

    def conflux_manifest_path
      File.join(conflux_folder_path, 'manifest.json')
    end

    # Jobs file is just a text file with a comma-delimited set of strings referencing the conflux jobs
    # that have already ran locally for a specific conflux bundle.
    def conflux_jobs_path
      File.join(conflux_folder_path, 'jobs.txt')
    end

    # conflux.yml serves as a reference to see which conflux config vars are currently
    # being set and used in the app.
    def conflux_yml_path
      File.join(conflux_folder_path, 'conflux.yml')
    end

    # Get an array of conflux jobs that have already ran locally
    def past_jobs
      File.exists?(conflux_jobs_path) ? File.read(conflux_jobs_path).split(',').map(&:strip) : []
    end

    def gemfile
      File.join(Dir.pwd, 'Gemfile')
    end

    # Get the conflux S3 public url
    def s3_url
      ENV['CONFLUX_S3_URL'] || 'http://confluxapp.s3-website-us-west-1.amazonaws.com'
    end

    def open_url(url)
      if running_on_a_mac?
        system "open #{url}"
      elsif running_on_windows?
        system "explorer #{url}"
      else
        # Probably some flavor of Linux
        system "xdg-open #{url}"
      end
    end

    def cmd_for_file_fetch(quiet: false)
      wget_check = running_on_windows? ? Open3.capture3('where wget') : Open3.capture3('which wget')

      # Return wget command if it exists
      return quiet ? 'wget -qO-' : 'wget -O-' if !wget_check.first.empty?

      # If wget doesn't exist, check to see if curl does
      curl_check = running_on_windows? ? Open3.capture3('where curl') : Open3.capture3('which curl')

      # Return curl command if it exists
      return 'curl -s' if !curl_check.first.empty?

      # Error out if neither wget not curl exist.
      error "File Fetch Error: 'wget' or 'curl' need to be installed in order to proceed."
    end

  end
end