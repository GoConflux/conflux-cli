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
      display("Installing #{name} ruby gem...")

      # returns array of [stdout, stderr, status]
      normal_install = Open3.capture3("gem install #{name}#{}")
      errors = normal_install[1]

      # If error exist
      if errors.empty?
        add_gem_to_gemfile(name, version: version) if add_to_gemfile
      else
        # Try sudo if getting permission error
        if errors.match(/Gem::FilePermissionError/)
          display('Got permission error...trying again with sudo.')
          system("sudo gem install #{name}")

          add_gem_to_gemfile(name, version: version) if add_to_gemfile
        else
          puts errors
        end
      end
    end

    # Append a gem to Gemfile if it doesn't already exist
    def add_gem_to_gemfile(name, version: nil)
      if File.read(gemfile).match(Regexp.new("'#{name}'|\"#{name}\"")).nil?
        display("Adding #{name} to Gemfile...")
        File.open(gemfile, 'a') { |f| f.puts "\n\ngem '#{name}'" }
      end
    end

  end
end