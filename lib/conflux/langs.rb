require 'open3'
require 'conflux/helpers'

module Conflux
  module Langs
    extend self
    extend Conflux::Helpers

    RUBY = 'ruby'

    def library_name(lang)
      case
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
        if errors.match(/Gem::FilePermissionError/)
          display('Got permission error...trying again with sudo.')
          system("sudo gem install #{name}")

          add_gem_to_gemfile(name, version: version) if add_to_gemfile
        else
          puts errors
        end
      end
    end

    def add_gem_to_gemfile(name, version: nil)
      # Write gem to Gemfile if not there already
      if File.read(gemfile).match(Regexp.new("'#{name}'|\"#{name}\"")).nil?
        display("Adding #{name} to Gemfile...")
        File.open(gemfile, 'a') { |f| f.puts "\n\ngem '#{name}'" }
      end
    end

  end
end