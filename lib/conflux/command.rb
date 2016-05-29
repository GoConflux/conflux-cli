require 'conflux/helpers'
require 'conflux/version'
require 'optparse'
require 'pathname'

GLOBAL_COMMAND_FILE = 'global'

module Conflux
  module Command
    extend Conflux::Helpers
    extend self

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

      # if command is in the @@commands map
      if command

        if seeking_command_help?(args)
          respond_with_command_help(cmd)
          return
        end

        if !command[:args].nil?
          # check for any invalid arguments passed in
          invalid_args = args - command[:args].keys

          # if invalid args exist, show the user how to properly use the command
          if !invalid_args.empty?
            handle_invalid_args(cmd, command, invalid_args)
            return
          end
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

    def handle_invalid_args(cmd, command, invalid_args)
      message = 'Invalid argument'
      message += 's' if invalid_args.length > 1
      invalid_args = invalid_args.map { |arg| "\"#{arg}\"" }.join(', ')

      # Explain to the user which arguments were invalid
      puts " !    #{message}: #{invalid_args}"

      # Explain which arguments ARE valid
      puts "\nValid arguments for \"conflux #{cmd}\":\n"

      valid_args = command[:args]

      command_info = usage_info(valid_args.keys, valid_args)

      puts "\n#{command_info}\n\n"
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

      commands_info = usage_info(commands.keys, commands)

      puts "\n#{header}"
      puts "\n#{commands_info}\n\n"
    end

    def seeking_command_help?(args)
      args.include?('-h') || args.include?('--help')
    end

    # Command-specific help
    def respond_with_command_help(cmd)
      command = get_cmd(cmd)

      puts "\nUsage: conflux #{cmd}  #  #{command[:description]}\n\n"

      valid_args = command[:args] || {}

      if !valid_args.empty?
        command_info = usage_info(valid_args.keys, valid_args)

        puts "Valid arguments:\n"
        puts "\n#{command_info}\n\n"
      end
    end

    def seeking_version?(cmd, args)
      args.length == 0 && (cmd == '--version' || cmd == '-v')
    end

    def respond_with_version
      display "conflux #{Conflux::VERSION}"
    end

    def usage_info(keys, map)
      commands_column_width = keys.max_by(&:length).length + 1

      commands_column_width += 2 if commands_column_width < 12

      # iterate through each of the commands, create an array
      # of strings in a `<command>  #  <description>` format. Sort
      # them alphabetically, and then join them with new lines.
      keys.map { |key|
        command = "  #{key}"

        for i in 0..(commands_column_width - key.length)
          command += ' '
        end

        command += "#  #{map[key][:description]}"
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

      valid_args = command_info_module.const_defined?('VALID_ARGS') ? command_info_module::VALID_ARGS : nil
      description = command_info_module.const_defined?('DESCRIPTION') ? command_info_module::DESCRIPTION : nil

      commands[command] = {
        method: action,
        klass: command_class,
        basename: basename,
        args: valid_args,
        description: description
      }
    end

  end
end