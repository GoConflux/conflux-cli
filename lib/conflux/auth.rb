require 'conflux/helpers'
require 'conflux/helpers/env'
require 'conflux/api/users'
require 'deps/netrc'
require 'fileutils'

module Conflux
  module Auth
    extend Conflux::Helpers
    extend self

    def login(new_user: false)
      @credentials = nil
      get_credentials(new_user: new_user)
    end

    def logout
      delete_credentials
      display 'Successfully logged out of Conflux.'
    end

    def get_credentials(new_user: false)
      @credentials ||= ask_for_and_save_credentials(new_user: new_user)
    end

    def ask_for_and_save_credentials(new_user: false)
      begin
        # Prompt the user for email/password
        @credentials = ask_for_credentials(new_user: new_user)

        # Write the creds to the user's ~/.netrc file
        write_credentials

        @credentials
      rescue => e
        delete_credentials
        display 'Authentication failed.'
        exit 1
      end
    end

    def write_credentials
      # Create all the parent directories for the .netrc file if they don't already exist
      FileUtils.mkdir_p(File.dirname(netrc_path))

      # Create ~/.netrc or ~/.netrc.gpg if encrypted
      FileUtils.touch(netrc_path)

      # Set permissions on the creds file
      FileUtils.chmod(0600, netrc_path) unless running_on_windows?

      # Add the credentials to the netrc file
      netrc[host] = @credentials

      # Save that shit
      netrc.save
    end

    def delete_credentials
      netrc.delete(host) && netrc.save if netrc
      @credentials = nil
    end

    def read_credentials
      netrc ? netrc[host] : nil
    end

    def ask_for_credentials(new_user: false)
      questions = new_user ?
        ['Enter an email to use for Conflux.', 'Create a password (typing will be hidden): '] :
        ['Enter your Conflux credentials.', 'Password (typing will be hidden): ']

      email = ask_free_response_question(questions[0], 'Email: ')
      print questions[1]
      password = running_on_windows? ? ask_for_password_on_windows : ask_for_password

      # Fetch a user token from the Conflux API with this email/password combo
      auth_response = Conflux::Api::Users.new.send(
        new_user ? 'join' : 'login',
        email,
        password
      )

      if new_user
        if auth_response['error'] == 'EmailTaken'
          display 'Email already taken. Try again with another email.'
          exit_no_error
        end

        display([
          "Joined Conflux as #{email}.",
          "A new Conflux bundle, #{auth_response['bundle']}, has been created for you.",
          "Run 'conflux init' inside your project's root directory to connect to your new bundle."
        ].join("\n"))
      else
        display "Successfully logged in as #{email}."
      end

      [email, auth_response['user_token']]
    end

    # Pulled straight from Heroku's CLI and not even tested yet.
    def ask_for_password_on_windows
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

    def ask_for_password
      begin
        echo_off # make the password input hidden
        password = allow_user_response
        puts
      ensure
        echo_on # flip input visibility back on
      end

      password
    end

    # Hide user input
    def echo_off
      with_tty do
        system 'stty -echo'
      end
    end

    # Show user input
    def echo_on
      with_tty do
        system 'stty echo'
      end
    end

    def get_email
      get_credentials[0]
    end

    def get_password
      get_credentials[1]
    end

    # Read the ~/.netrc file, which contains user credentials for various host domains
    def netrc
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

    def netrc_path
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
