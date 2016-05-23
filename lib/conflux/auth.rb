require 'conflux/helpers'

module Conflux
  module Auth
    extend Conflux::Helpers

    def self.login
      @credentials = nil
      get_credentials
    end

    def self.get_credentials
      # should be: @credentials ||= (read_credentials || login)
      @credentials ||= (ask_for_credentials || login)
    end

    def self.ask_for_credentials
      email = ask_free_response_question('Enter your Conflux credentials.', 'Email: ')
      print 'Password (typing will be hidden): '
      password = running_on_windows? ? ask_for_password_on_windows : ask_for_password

      [email, api_key(email, password)]
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

  end
end
