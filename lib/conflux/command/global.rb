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

  # Establish connection between pwd and a chosen conflux app
  def init
    conflux_folder_path = "#{Dir.pwd}/.conflux/"
    conflux_manifest_path = File.join(conflux_folder_path, 'manifest.json')

    if File.exists?(conflux_manifest_path)
      manifest_json = JSON.parse(File.read(conflux_manifest_path)) rescue {}
      display("Directory already connected to Conflux app: #{manifest_json['name']}")
    else
      apps_api = Conflux::Api::Apps.new

      # Get list of all user's app slugs
      app_slugs = apps_api.list

      # Ask user which app this project belongs to:
      selected_app_index = ask_mult_choice_question('Which Conflux app does this project belong to?', app_slugs)

      selected_app_slug = app_slugs[selected_app_index]

      display 'Configuring manifest.json...'

      # Fetch manifest info for that selected app
      manifest_json = apps_api.manifest(selected_app_slug)

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

      display("Successfully connected project to Conflux app: #{manifest_json['name']}")
    end

    # Add /.conflux/ to .gitignore if not already
    gitignore = File.join(Dir.pwd, '.gitignore')
    gi_entries = File.read(gitignore).split("\n")

    if !gi_entries.include?('.conflux/') && !gi_entries.include?('/.conflux/')
      File.open(gitignore, 'a') { |f| f.puts "\n/.conflux/\n" }
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

  end

end