require 'conflux/helpers'
require 'optparse'

module Conflux
  module Command

    class CommandFailed < RuntimeError; end

    extend Conflux::Helpers

    def self.load
      # Require all the command files
      Dir[File.join(File.dirname(__FILE__), 'command', '*.rb')].each do |file|
        require file
      end
    end

    def self.run(cmd, args = [])
      object, method = prepare_run(cmd, args.dup)
      object.send(method)
    end

    def self.prepare_run(cmd, args = [])
      command = parse(cmd)

      # If seeking help
      if args.include?('-h') || args.include?('--help')
        args.unshift(cmd) unless cmd =~ /^-.*/
        cmd = 'help'
        command = parse(cmd)
      end

      # If seeking version info
      if cmd == '--version'
        cmd = 'version'
        command = parse(cmd)
      end

      @current_command = cmd
      @anonymized_args, @normalized_args = [], []

      opts = {}
      invalid_options = []

      puts "CURRENT COMMAND #{command}"

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

    def self.global_options
      @global_options ||= []
    end

    def self.parse(cmd)
      commands[cmd] || commands[command_aliases[cmd]]
    end

    def self.commands
      @@commands ||= {}
    end

    def self.command_aliases
      @@command_aliases ||= {}
    end

  end
end