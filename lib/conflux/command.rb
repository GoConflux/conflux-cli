require 'conflux/helpers'
require 'conflux/version'
require 'optparse'
require 'pathname'

GLOBAL_COMMAND_FILE = 'global'

module Conflux
  module Command
    extend Conflux::Helpers
    extend self

    VARIABLE_CMD_ARGS = ['APP', 'ADDON']

    class CommandFailed < RuntimeError; end

    def load
      # Require all the ruby command files
      command_file_paths.each do |file|
        require file

        # Get basename for the file without the extension (Ex: global, app, etc.)
        basename = get_basename_from_file(file)

        # Camelcase the basename to be the class name
        class_name = camelize(basename)

        # Store reference to the class associated with this basename
        command_class = Conflux::Command.const_get(class_name)

        # For each of the user-defined methods inside this class, create a command for it
        manually_added_methods(command_class).each { |method|
          register_command(basename, method.to_s, command_class, global: (basename == GLOBAL_COMMAND_FILE))
        }
      end
    end

    def run(cmd, args = [])
      command = get_cmd(cmd)

      if command
        if seeking_command_help?(args)
          puts "\nUse Case: #{command[:description]}\n"
          respond_with_command_help(cmd)
          return
        end

        if !valid_args?(args, command[:args])
          handle_invalid_args(cmd)
          return
        end

        command_instance = command[:klass].new(args.dup)
        command_instance.send(command[:method])
      elsif seeking_version?(cmd, args)
        respond_with_version
      elsif seeking_help?(cmd, args)
        respond_with_help
      else
        error([
          "`#{cmd}` is not a conflux command.",
          "See `conflux help` for a list of available commands."
        ].compact.join("\n"))
      end
    end

    def valid_args?(args, accepted_arg_formats)
      valid_args = false

      accepted_arg_formats.each { |format|
        # if no arguments exist, and no arguments is an accepted format, args are valid.
        if format.empty? && args.empty?
          valid_args = true
        else
          passed_in_args = args.clone

          format.each_with_index { |arg, i|
            passed_in_args[i] = arg if VARIABLE_CMD_ARGS.include?(arg)
          }

          @invalid_args = passed_in_args - format

          valid_args = true if passed_in_args == format
        end
      }

      valid_args
    end

    def handle_invalid_args(cmd)
      if !@invalid_args.empty?
        message = 'Invalid argument'
        message += 's' if @invalid_args.length > 1
        args = @invalid_args.map { |arg| "\"#{arg}\"" }.join(', ')

        puts " !    #{message}: #{args}"
      else
        puts " !    Invalid command usage"
      end

      respond_with_command_help(cmd)
    end

    def seeking_help?(cmd, args)
      args.length == 0 && (cmd == 'help' || cmd == '-h' || cmd.empty?)
    end

    def respond_with_help
      header = [
        'Usage: conflux COMMAND [command-specific-arguments]',
        'Type "conflux COMMAND --help" for more details about each command',
        'Commands:'
      ].join("\n\n")

      commands_info = usage_info(commands)

      puts "\n#{header}"
      puts "\n#{commands_info}\n\n"
    end

    def seeking_command_help?(args)
      args.include?('-h') || args.include?('--help')
    end

    # Command-specific help
    def respond_with_command_help(cmd)
      command = get_cmd(cmd)

      if command[:no_app_means_local]
        puts "\n* NOTE: If no app is specified, the conflux app connected to your current directory will be used *\n"
      end

      puts "\nValid Command Formats:\n\n"

      command[:args].each { |format|
        puts "#  conflux #{cmd} #{format.join(' ')}\n"
      }

      puts "\n"
    end

    def seeking_version?(cmd, args)
      args.length == 0 && (cmd == '--version' || cmd == '-v')
    end

    def respond_with_version
      display "conflux #{Conflux::VERSION}"
    end

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

    def get_basename_from_file(file)
      basename = Pathname.new(file).basename.to_s
      basename = basename[0..(basename.rindex('.') - 1)]
      basename
    end

    def command_file_paths
      abstract_file = File.join(File.dirname(__FILE__), 'command', 'abstract_command.rb')
      Dir[File.join(File.dirname(__FILE__), 'command', '*.rb')] - [abstract_file]
    end

    def get_cmd(cmd)
      commands[cmd]
    end

    def commands
      @@commands ||= {}
    end

    def register_command(basename, action, command_class, global: false)
      if global
        command = action
      else
        command = (action == 'index') ? basename : "#{basename}:#{action}"
      end

      command_info_module = command_class::CommandInfo.const_get(camelize(action))

      valid_args = command_info_module.const_defined?('VALID_ARGS') ?
        command_info_module::VALID_ARGS : []

      description = command_info_module.const_defined?('DESCRIPTION') ?
        command_info_module::DESCRIPTION : ''

      no_app_means_local = command_info_module.const_defined?('NO_APP_MEANS_LOCAL') ?
        command_info_module::NO_APP_MEANS_LOCAL : false

      commands[command] = {
        method: action,
        klass: command_class,
        basename: basename,
        args: valid_args,
        description: description,
        no_app_means_local: no_app_means_local
      }
    end

  end
end