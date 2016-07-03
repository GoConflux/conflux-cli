require 'open3'
require 'conflux/helpers'

module Conflux
  module Langs
    extend self
    extend Conflux::Helpers

    RUBY = 'ruby'

    # Return library "name" for a certain language
    def library_name(lang)
      case lang
        when RUBY
          'gem'
      end
    end

    def install_ruby_gem(name, version: nil, add_to_gemfile: false)
      # if the gem hasn't been installed yet
      if !gem_installed?(name)
        command = "gem install #{name}"
        command += " -v #{version}" if !version.nil?

        display("Installing #{name} ruby gem...")

        install = Open3.capture3(command)
        errors = install[1]

        if errors.empty?
          add_gem_to_gemfile(name, version: version) if add_to_gemfile
        else
          # Try sudo if getting permission error
          if errors.match(/Gem::FilePermissionError/)
            display('Got permission error...trying again with sudo.')
            system("sudo #{command}")

            add_gem_to_gemfile(name, version: version) if add_to_gemfile
          else
            puts "Error installing #{name} ruby gem: #{errors}"
          end
        end

      # The gem has already been installed on this computer (regardless of version). Don't reinstall.
      else
        display("#{name} gem already installed.")
        # Since this gem is already installed on this computer with a certain version,
        # let's use THIS version when adding the gem to the Gemfile...not the version passed in.
        add_gem_to_gemfile(name, version: version_of_gem_installed(name)) if add_to_gemfile
      end
    end

    def gem_installed?(name)
      !Open3.capture3("gem which #{name}").first.empty?
    end

    def version_of_gem_installed(gem)
      Open3.capture3("gem which #{gem}").first.split('/').reverse[2].gsub("#{gem}-", '')
    end

    # Append a gem to Gemfile if it doesn't already exist
    def add_gem_to_gemfile(name, version: nil)
      # if Gemfile doesn't already contain this gem, add it with the passed-in version (if version exists)
      if File.read(gemfile).match(Regexp.new("'#{name}'|\"#{name}\"")).nil?
        display("Adding #{name} to Gemfile...")
        line = "gem '#{name}'"
        line += ", '#{version}'" if !version.nil?

        File.open(gemfile, 'a') { |f| f.puts "\n#{line}\n" }
      end
    end

  end
end