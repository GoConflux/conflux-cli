require 'conflux/helpers'
require 'conflux/version'
require 'optparse'
require 'pathname'

module Conflux
  module Command
    extend Conflux::Helpers
    extend self

    CMD_BLACKLIST = ['BUNDLE', 'SERVICE', 'TEAM', 'EMAIL', 'HEROKU_APP', 'NEW_BUNDLE']

    # Finds file/method for command
    def find_command(cmd, args = [])
      @current_cmd = cmd
      @current_args = args

      respond_with_help if seeking_help?
      respond_with_version if seeking_version?

      # Separate out primary/secondary commands based on if command was namespaced
      # e.g. `conflux services vs. conflux services:add`
      primary_cmd, secondary_cmd = @current_cmd.split(':')

      # Get the command file path (string) for the primary command
      primary_cmd_file = file_for_command(primary_cmd)

      # If the primary command has it's own file, require it
      primary_cmd_file_exists = File.exists?(primary_cmd_file)
      require primary_cmd_file if primary_cmd_file_exists

      # If a secondary command exists, the primary_cmd_file must be where our command method lies
      if !secondary_cmd.nil?
        error_no_command if !primary_cmd_file_exists

        # Get command_klass for file path. Example response --> Conflux::Command::Services
        command_klass = klass_for_file(primary_cmd_file)

        # Error out if the command klass doesn't have a method named <secondary_cmd>
        error_no_command if !klass_has_method?(command_klass, secondary_cmd)

        run(command_klass, secondary_cmd)

      # If there's no secondary command, there are 2 options for where the command method could be (in order of priority):
      # (1) Inside the primary command file as the 'index' method
      # (2) Inside the global command file, as a method named <primary_cmd>
      else
        # Store lambda for later
        try_global = lambda {
          require 'conflux/command/global'
          command_klass = Conflux::Command::Global
          error_no_command if !klass_has_method?(command_klass, primary_cmd)
          run(command_klass, primary_cmd)
        }

        # Number 1 above. If primary_cmd file exists, call the index method on it if it exists.
        # If index method doens't exist, check to see if method is a global command.
        if primary_cmd_file_exists
          # Get command_klass for file path. Example response --> Conflux::Command::Services
          command_klass = klass_for_file(primary_cmd_file)

          klass_has_method?(command_klass, 'index') ? run(command_klass, 'index') : try_global.call

        # Number 2 above. Check to see if method is a global command inside command/global.rb
        else
          try_global.call
        end
      end
    end

    # Call a method on a klass with certain arguments.
    # Will validate arguments first before calling method.
    def run(klass, method)
      # Get the command info for this method on this klass
      command_info_module = klass::CommandInfo.const_get(camelize(method))

      # If seeking help for this command with --help or -h
      if seeking_command_help?(@current_args)
        puts "\nPurpose: #{command_description(command_info_module)}\n"

        # respond with command-specific help
        respond_with_command_help(command_info_module)
        return
      end

      # get the valid arguments defined for this comand
      valid_args = command_valid_args(command_info_module)

      if !valid_args?(valid_args)
        handle_invalid_args(command_info_module)
        return
      end

      klass.new(@current_args.dup).send(method)
    end

    # Get a command klass back from a file path:
    # Example I/O: 'command/bundles' --> Conflux::Command::Bundles
    def klass_for_file(file)
      # Get basename for the file without the extension
      basename = get_basename_from_file(file)

      # Camelcase the basename to be the klass name
      klass_name = camelize(basename)

      # return the command klass for this klass_name
      Conflux::Command.const_get(klass_name)
    end

    # Create a command file path from the name of a command
    def file_for_command(command)
      File.join(File.dirname(__FILE__), 'command', "#{command}.rb")
    end

    # Check to see if user-defined method exists on a klass
    def klass_has_method?(klass, method)
      manually_added_methods(klass).include?(method.to_sym)
    end

    def error_no_command
      error([
        "`#{@current_cmd}` is not a conflux command.",
        "Type `conflux help` for a list of available commands."
      ].compact.join("\n"))
    end

    # Check if passed-in arguments are valid for a specific format
    def valid_args?(accepted_arg_formats)
      valid_args = false

      accepted_arg_formats.each { |format|
        # if no arguments exist, and no arguments is an accepted format, args are valid.
        if format.empty? && @current_args.empty?
          valid_args = true
        else
          passed_in_args = @current_args.clone

          format.each_with_index { |arg, i|
            passed_in_args[i] = arg if CMD_BLACKLIST.include?(arg)
          }

          @invalid_args = passed_in_args - format - [nil]

          valid_args = true if passed_in_args == format
        end
      }

      valid_args
    end

    # Respond to the user in the instance of invalid arguments.
    def handle_invalid_args(command_info_module)
      if !@invalid_args.empty?
        message = 'Invalid argument'
        message += 's' if @invalid_args.length > 1
        args = @invalid_args.map { |arg| "\"#{arg}\"" }.join(', ')

        puts " !    #{message}: #{args}"
      else
        puts " !    Invalid command usage"
      end

      respond_with_command_help(command_info_module)
    end

    def command_valid_args(command_info_module)
      command_info_module.const_defined?('VALID_ARGS') ? command_info_module::VALID_ARGS : []
    end

    def command_description(command_info_module)
      command_info_module.const_defined?('DESCRIPTION') ? command_info_module::DESCRIPTION : ''
    end

    def use_local_app_if_not_defined?(command_info_module)
      command_info_module.const_defined?('NO_BUNDLE_MEANS_LOCAL') ? command_info_module::NO_BUNDLE_MEANS_LOCAL : false
    end

    # stdin is `conflux help` or `conflux -h`
    def seeking_help?
      @current_args.length == 0 && (@current_cmd.empty? || ['help', '--help', '-h'].include?(@current_cmd))
    end

    def respond_with_help
      create_commands_map

      header = [
        'Usage: conflux COMMAND [command-specific-arguments]',
        'Type "conflux COMMAND --help" for more details about each command',
        'Commands:'
      ].join("\n\n")

      commands_info = usage_info(commands)

      puts "\n#{header}"
      puts "\n#{commands_info}\n\n"
      exit(0)
    end

    # Create a commands map to respond to `conflux help` with.
    def create_commands_map
      # Require all the ruby command files
      command_file_paths.each do |file|
        require file

        # Get basename for the file without the extension
        basename = get_basename_from_file(file)

        # Camelcase the basename to be the klass name
        klass_name = camelize(basename)

        # return the command klass for this klass_name
        command_klass = Conflux::Command.const_get(klass_name)

        # For each of the user-defined methods inside this class, create a command for it
        manually_added_methods(command_klass).each { |method|
          register_command(basename, method.to_s, command_klass, global: basename == 'global')
        }
      end
    end

    # Format a map of commands into help output format
    def usage_info(map)
      keys = map.keys
      commands_column_width = keys.max_by(&:length).length + 1
      commands_column_width += 2 if commands_column_width < 12

      # iterate through each of the commands, create an array
      # of strings in a `<command>  #  <description>` format. Sort
      # them alphabetically, and then join them with new lines.
      keys.map { |key|
        command = "  #{key}"
        command += (' ' * (commands_column_width - key.length + 1))
        command += "#  #{map[key][:description]}"
        command
      }.sort_by{ |k| k.downcase }.join("\n")
    end

    # Seeking command-specific help. e.g. `conflux bundles --help`
    def seeking_command_help?(args)
      args.include?('-h') || args.include?('--help')
    end

    # Respond to command-specific help
    def respond_with_command_help(command_info_module)
      help = ''

      if use_local_app_if_not_defined?(command_info_module)
        help += "\n* NOTE: If no app is specified, the conflux bundle connected to your current directory will be used *\n"
      end

      help += "\nValid Command Formats:\n\n"

      command_valid_args(command_info_module).each { |format|
        help += "#  conflux #{@current_cmd} #{format.join(' ')}\n"
      }

      puts "#{help}\n"
    end

    # stdin is `conflux --version` or `conflux -v`
    def seeking_version?
      @current_args.length == 0 && (@current_cmd == '--version' || @current_cmd == '-v')
    end

    def respond_with_version
      display "conflux #{Conflux::VERSION}"
      exit(0)
    end

    # Return just the basename for a file, no extensions.
    def get_basename_from_file(file)
      basename = Pathname.new(file).basename.to_s
      basename[0..(basename.rindex('.') - 1)]
    end

    # Feturn an array of all command file paths, with the exception of abstract_command.rb
    def command_file_paths
      abstract_file = File.join(File.dirname(__FILE__), 'command', 'abstract_command.rb')
      Dir[File.join(File.dirname(__FILE__), 'command', '*.rb')] - [abstract_file]
    end

    def commands
      @@commands ||= {}
    end

    # register a command's info to the @@commands map - utilized when calling `conflux help`
    def register_command(basename, action, command_class, global: false)
      command = global ? action : (action == 'index' ? basename : "#{basename}:#{action}")

      command_info_module = command_class::CommandInfo.const_get(camelize(action))

      commands[command] = { description: command_description(command_info_module) }
    end

  end
end