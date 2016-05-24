require 'conflux/helpers'
require 'conflux/helpers/env'
require 'netrc'
require 'fileutils'

module Conflux
  module Auth
    extend Conflux::Helpers

    attr_reader :credentials

    def self.login
      @credentials = nil
      get_credentials
    end

    def self.logout
      delete_credentials
    end

    def self.get_credentials
      @credentials ||= ask_for_and_save_credentials
    end

    def self.ask_for_and_save_credentials
      begin
        @credentials = ask_for_credentials

        display "Logged in as #{@credentials[0]} of Refletktive"

        write_credentials

        # check user is authed with auth_test ajax call

        @credentials
      rescue => e
        delete_credentials
        display 'Authentication failed.'
        exit 1
      end
    end

    def self.write_credentials
      # Create all the parent directories for the .netrc file if they don't already exist
      FileUtils.mkdir_p(File.dirname(netrc_path))

      # Create ~/.netrc or ~/.netrc.gpg if encrypted
      FileUtils.touch(netrc_path)

      # Set permissions on the creds file
      FileUtils.chmod(0600, netrc_path) unless running_on_windows?

      # Add the credentials to the netrc file
      netrc[host] = @credentials

      netrc.save
    end

    def self.delete_credentials
      netrc.delete(host) && netrc.save if netrc
      @credentials = nil
    end

    def self.read_credentials
      netrc[full_host_uri.host] if netrc
    end

    def self.ask_for_credentials
      email = ask_free_response_question('Enter your Conflux credentials.', 'Email: ')
      print 'Password (typing will be hidden): '
      password = running_on_windows? ? ask_for_password_on_windows : ask_for_password

      [email, password]
    end

    def self.ask_for_password_on_windows
      require 'Win32API'
      char = nil
      password = ''

      while char = Win32API.new('msvcrt', '_getch', [ ], 'L').Call do
        break if char == 10 || char == 13 # received carriage return or newline
        if char == 127 || char == 8 # backspace and delete
          password.slice!(-1, 1)
        else
          # windows might throw a -1 at us so make sure to handle RangeError
          (password << char.chr) rescue RangeError
        end
      end

      puts
      password
    end

    def self.ask_for_password
      begin
        echo_off
        password = allow_user_response
        puts
      ensure
        echo_on
      end

      password
    end

    def self.get_email
      get_credentials[0]
    end

    def self.get_password
      get_credentials[1]
    end

    def self.api_key(email = get_email, password = get_password)
      # get valid user token for email/password combo by making ajax post
      api_key = '1234567'
      api_key
    rescue => e
      error e.message
      exit 1
    end

    def self.echo_off
      with_tty do
        system 'stty -echo'
      end
    end

    def self.echo_on
      with_tty do
        system 'stty echo'
      end
    end

    def self.netrc
      @netrc ||= begin
        File.exists?(netrc_path) && Netrc.read(netrc_path)
      rescue => e
        case e.message
          when /^Permission bits for/
            abort("#{e.message}.\nYou should run `chmod 0600 #{netrc_path}` so that your credentials are NOT accessible by others.")
          when /EACCES/
            error("Error reading #{netrc_path}\n#{e.message}\nMake sure this user can read/write this file.")
          else
            error("Error reading #{netrc_path}\n#{e.message}\nYou may need to delete this file and run `conflux login` to recreate it.")
        end
      end
    end

    def self.netrc_path
      default = begin
        File.join(Conflux::Helpers::Env['NETRC'] || home_directory, Netrc.netrc_filename)
      rescue NoMethodError # happens if old netrc gem is installed
        Netrc.default_path
      end

      encrypted = default + '.gpg'

      File.exists?(encrypted) ? encrypted : default
    end

  end
end
