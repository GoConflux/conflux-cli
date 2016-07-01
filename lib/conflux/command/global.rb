require 'conflux/command/abstract_command'
require_relative '../auth'
require_relative '../langs'
require_relative '../pull'
require_relative '../api/apps'
require_relative '../api/users'
require 'fileutils'
require 'json'
require 'open3'

class Conflux::Command::Global < Conflux::Command::AbstractCommand

  def login
    Conflux::Auth.login
  end

  def logout
    Conflux::Auth.logout
  end

  def init
    ensure_authed

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
      resp = Conflux::Api::Apps.new.manifest(selected_app_slug)
      manifest_json = resp[:manifest]

      # Create /.conflux/ folder if doesn't already exist
      FileUtils.mkdir_p(conflux_folder_path) if !File.exists?(conflux_folder_path)

      # Write this app info to a new manifest.json file for the user
      File.open(conflux_manifest_path, 'w+') do |f|
        f.write(JSON.pretty_generate(manifest_json))
      end

      if is_rails_project?
        Conflux::Langs.install_ruby_gem('conflux', version: resp[:latest_gem_version], add_to_gemfile: true)
      elsif is_node_project?
        # Coming soon
      end

      display("Successfully connected project to conflux app: #{manifest_json['app']['name']}")
    end

    gitignore = File.join(Dir.pwd, '.gitignore')
    gi_entries = File.exists?(gitignore) ? File.read(gitignore).split("\n") : nil

    # Add /.conflux/ to .gitignore if not already
    if !gi_entries.nil? && !gi_entries.include?('.conflux/') && !gi_entries.include?('/.conflux/')
      File.open(gitignore, 'a') { |f| f.puts "\n/.conflux/\n" }
    end
  end

  def open
    ensure_authed

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
      reply_no_conflux_app
    end
  end

  def pull
    ensure_authed
    Conflux::Pull.perform
  end

  def cost
    resp = Conflux::Api::Apps.new.cost(@args)
    display "#{resp['app_slug']} monthly cost: #{resp['cost']}"
  end

  def teams
    teams = Conflux::Api::Users.new.teams
    puts to_table(teams, ['slug', 'name'])
  end

  def configs
    configs_map = Conflux::Api::Apps.new.configs(@args)

    if configs_map.empty?
      puts 'No config vars currently exist for this app.'
    else
      configs_arr = []

      configs_map.values.each { |configs|
        configs_arr += configs
      }

      text = ''

      configs_arr.sort_by { |info| info['name'] }.each { |config|
        description = (config['description'].nil? || config['description'].empty?) ? '' : " # #{config['description']}"
        text += "#{config['name']}#{description}\n"
      }

      puts text
    end
  end

  def update
    wget_check = Open3.capture3('which wget')

    # Choose command that will be used to fetch file contents based on if
    # `wget` is intalled. If `wget` isn't installed, default to using `curl`.
    command = wget_check.first.empty? ? 'curl -s' : 'wget -O-'

    with_tty do
      system "#{command} #{host_url}/install.sh | sh"
    end
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Login
      DESCRIPTION = 'Login to your conflux account'
      VALID_ARGS = [ [] ]
    end

    module Logout
      DESCRIPTION = 'Log out of your conflux account'
      VALID_ARGS = [ [] ]
    end

    module Init
      DESCRIPTION = 'Connect current directory to one of your conflux apps'
      VALID_ARGS = [ [] ]
    end

    module Open
      DESCRIPTION = 'Open Web UI for current conflux app'
      VALID_ARGS = [ [] ]
    end

    module Pull
      DESCRIPTION = 'Fetch any new conflux jobs/configs you don\'t have locally'
      VALID_ARGS = [ [] ]
    end

    module Cost
      DESCRIPTION = 'View the monthly cost for a conflux app'
      VALID_ARGS = [ [], ['-a', 'APP'] ]
      NO_APP_MEANS_LOCAL = true
    end

    module Teams
      DESCRIPTION = 'List all of your conflux teams'
      VALID_ARGS = [ [] ]
    end

    module Configs
      DESCRIPTION = 'List all configs for a conflux app'
      VALID_ARGS = [ [], ['-a', 'APP'] ]
      NO_APP_MEANS_LOCAL = true
    end

    module Update
      DESCRIPTION = 'Update to the latest version of the conflux toolbelt'
      VALID_ARGS = [ [] ]
    end

  end

end