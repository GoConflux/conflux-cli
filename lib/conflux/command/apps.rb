require 'conflux/command/abstract_command'
require_relative '../api/users'
require_relative '../api/apps'
require_relative '../pull'
require 'fileutils'
require 'open3'

class Conflux::Command::Apps < Conflux::Command::AbstractCommand

  def index
    apps_map = Conflux::Api::Users.new.apps

    apps_map.each { |team, apps|
      puts "\n#{team}:\n\n"
      apps.each { |slug| puts "  #{slug}" }
    }

    puts "\n"
  end

  def current
    ensure_authed

    if File.exists?(conflux_manifest_path)
      manifest_json = JSON.parse(File.read(conflux_manifest_path)) rescue {}
      name = manifest_json['app']['name']

      if name.nil?
        reply_no_conflux_app
      else
        display "Directory currently connected to conflux app: #{name}"
      end
    else
      reply_no_conflux_app
    end
  end

  def use
    # Fetch manifest info for that selected app
    manifest_json = Conflux::Api::Apps.new.manifest(@args[0])['manifest']

    # Create new .conflux/ folder
    FileUtils.rm_rf(conflux_folder_path)
    FileUtils.mkdir_p(conflux_folder_path)

    # Write this app info to a new manifest.json file for the user
    File.open(conflux_manifest_path, 'w+') do |f|
      f.write(JSON.pretty_generate(manifest_json))
    end

    Conflux::Pull.perform

    display("Successfully connected project to conflux app: #{manifest_json['app']['name']}")
  end

  def heroku_use
    creds = Conflux::Api::Apps.new.team_user_app_tokens(@args[0])

    heroku_check = Open3.capture3('which heroku')

    if heroku_check.first.empty?
      display [
        "The Heroku toolbelt needs to be installed before running this command.",
        "Go to https://toolbelt.heroku.com to install this toolbelt."
      ].join("\n")

      return
    end

    with_tty do
      system "heroku config:set CONFLUX_USER=#{creds['CONFLUX_USER']} CONFLUX_APP=#{creds['CONFLUX_APP']} -a #{@args[2]}"
      display "Successfully connected Heroku app '#{@args[2]}' to conflux app '#{@args[0]}'."
    end
  end

  def clone
    display "Cloning apps coming soon!"
  end

  #--------------------------------- -------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'List all of your conflux apps'
      VALID_ARGS = [ [] ]
    end

    module Current
      DESCRIPTION = 'Shows which conflux app is connected to the current directory'
      VALID_ARGS = [ [] ]
    end

    module Use
      DESCRIPTION = 'Set which conflux app to use for the current directory'
      VALID_ARGS = [ ['APP'] ]
    end

    module HerokuUse
      DESCRIPTION = 'Set which conflux app to use for a specific heroku app'
      VALID_ARGS = [ ['APP', '-a', 'HEROKU_APP'] ]
    end

    module Clone
      DESCRIPTION = 'Clone a conflux app'
      VALID_ARGS = [ ['APP', 'NEW_APP'] ]
    end

  end

end