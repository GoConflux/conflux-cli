require 'conflux/command/abstract_command'
require_relative '../auth'
require_relative '../api/apps'
require 'fileutils'
require 'json'
require 'pry'

class Conflux::Command::Global < Conflux::Command::AbstractCommand

  def login
    Conflux::Auth.login
  end

  def logout
    Conflux::Auth.logout
  end

  def init
    if File.exists?(conflux_manifest_path)
      manifest_json = JSON.parse(File.read(conflux_manifest_path)) rescue {}
      display("Directory already connected to conflux app: #{manifest_json['app']['name']}")
    else
      # Get map of all user's apps grouped by team
      apps_map = Conflux::Api::Users.new.apps

      # Ask user which app this project belongs to:
      selected_app_slug = prompt_user_to_select_app(apps_map)

      display 'Configuring manifest.json...'

      # Fetch manifest info for that selected app
      manifest_json = Conflux::Api::Apps.new.manifest(selected_app_slug)

      # Create /.conflux/ folder if doesn't already exist
      FileUtils.mkdir_p(conflux_folder_path) if !File.exists?(conflux_folder_path)

      # Write this app info to a new manifest.json file for the user
      File.open(conflux_manifest_path, 'w+') do |f|
        f.write(JSON.pretty_generate(manifest_json))
      end

      # Determine which conflux gem/client to install based on type of project
      if is_rails_project?
        gemfile = File.join(Dir.pwd, 'Gemfile')

        # Write gem 'conflux to Gemfile if not there already
        if File.read(gemfile).match(/'conflux'|"conflux"/).nil?
          display('Adding conflux to Gemfile...')
          File.open(gemfile, 'a') { |f|  f.puts "\n\ngem 'conflux'" }
        end

        # Run `gem install conflux` if gem not already installed
        install_conflux_gem if !gem_exists?

      elsif is_node_project?
        # write to package.json the conflux-js node_module
      end

      display("Successfully connected project to conflux app: #{manifest_json['app']['name']}")
    end

    # Add /.conflux/ to .gitignore if not already
    gitignore = File.join(Dir.pwd, '.gitignore')
    gi_entries = File.read(gitignore).split("\n")

    if !gi_entries.include?('.conflux/') && !gi_entries.include?('/.conflux/')
      File.open(gitignore, 'a') { |f| f.puts "\n/.conflux/\n" }
    end
  end

  def open
    if File.exists?(conflux_manifest_path)
      manifest_json = JSON.parse(File.read(conflux_manifest_path)) rescue {}
      app_url = manifest_json['app']['url']

      if !app_url.nil?
        display "Opening conflux app #{manifest_json['app']['name']}..."
        with_tty do
          system "open #{app_url}"
        end
      else
        display "Could not find valid app url inside your conflux manifest.json"
      end
    else
      display "Directory not currently connected to a conflux app.\n"\
        "Run \"conflux init\" to a establish a connection with one of your apps."
    end
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Login
      DESCRIPTION = 'Login to a conflux team'
      VALID_ARGS = {}
    end

    module Logout
      DESCRIPTION = 'Log out of current conflux team'
      VALID_ARGS = {}
    end

    module Init
      DESCRIPTION = 'Connect current directory to one of your conflux apps'
      VALID_ARGS = {}
    end

    module Open
      DESCRIPTION = 'Open Web UI for current conflux app'
      VALID_ARGS = {}
    end

  end

end