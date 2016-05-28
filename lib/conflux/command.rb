require 'conflux/helpers'
require 'conflux/version'
require 'optparse'
require 'pathname'
require 'pry'

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
      respond_with_help and return if seeking_help?(cmd, args)
      respond_with_version and return if seeking_version?(cmd, args)

      command_class, method = prep_for_run(cmd, args.dup)
      command_class.send(method)
    end

    def prep_for_run(cmd, args = [])
      command = get_cmd(cmd)
      @current_command = cmd
      @anonymized_args, @normalized_args = [], []

      opts = {}
      invalid_options = []

      option_parser = OptionParser.new do |parser|
        # remove OptionParsers Officious['version'] to avoid conflicts
        parser.base.long.delete('version')

        (global_options + (command && command[:options] || [])).each do |option|
          parser.on(*option[:args]) do |value|
            option[:proc].call(value) if option[:proc]

            opts[option[:name].gsub('-', '_').to_sym] = value

            ARGV.join(' ') =~ /(#{option[:args].map {|arg| arg.split(' ', 2).first}.join('|')})/

            @anonymized_args << "#{$1} _"

            @normalized_args << "#{option[:args].last.split(' ', 2).first} _"
          end
        end
      end

      begin
        option_parser.order!(args) do |nonopt|
          invalid_options << nonopt
          @anonymized_args << '!'
          @normalized_args << '!'
        end
      rescue OptionParser::InvalidOption => ex
        invalid_options << ex.args.first
        @anonymized_args << '!'
        @normalized_args << '!'
        retry
      end

      args.concat(invalid_options)

      @current_args = args
      @current_options = opts
      @invalid_arguments = invalid_options

      @anonymous_command = [ARGV.first, *@anonymized_args].join(' ')

      if command
        command_instance = command[:klass].new(args.dup, opts.dup)

        if !@normalized_args.include?('--app _') && (command_instance.app rescue nil)
          @normalized_args << '--app _'
        end

        @normalized_command = [ARGV.first, @normalized_args.sort_by {|arg| arg.gsub('-', '')}].join(' ')

        [command_instance, command[:method]]
      else
        error([
          "`#{cmd}` is not a conflux command.",
          "See `conflux help` for a list of available commands."
        ].compact.join("\n"))
      end
    end

    def respond_with_help
      display 'help'
    end

    def respond_with_version
      display "conflux #{Conflux::VERSION}"
    end

    def seeking_help?(cmd, args)
      args.length == 0 && (cmd == 'help' || cmd == '-h' || cmd.empty?)
    end

    def seeking_version?(cmd, args)
      args.length == 0 && (cmd == '--version' || cmd == '-v')
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

    def global_options
      @global_options ||= []
    end

    def get_cmd(cmd)
      commands[cmd] || commands[command_aliases[cmd]]
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

      commands[command] = {
        method: action,
        klass: command_class,
        args: command_info_module::VALID_ARGS,
        description: command_info_module::DESCRIPTION
      }
    end

    def command_aliases
      @@command_aliases ||= {}
    end

    def namespaces
      @@namespaces ||= {}
    end

  end
end