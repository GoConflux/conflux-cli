require 'conflux/command/abstract_command'
require_relative '../api/users'
require_relative '../api/bundles'
require_relative '../pull'
require 'fileutils'
require 'open3'

class Conflux::Command::Bundles < Conflux::Command::AbstractCommand

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
        display "Directory currently connected to conflux bundle: #{name}"
      end
    else
      reply_no_conflux_app
    end
  end

  def use
    # Fetch manifest info for that selected app
    manifest_json = Conflux::Api::Bundles.new.manifest(@args[0])['manifest']

    # Create new .conflux/ folder
    FileUtils.rm_rf(conflux_folder_path)
    FileUtils.mkdir_p(conflux_folder_path)

    # Write this app info to a new manifest.json file for the user
    File.open(conflux_manifest_path, 'w+') do |f|
      f.write(JSON.pretty_generate(manifest_json))
    end

    Conflux::Pull.perform

    display("Successfully connected project to conflux bundle: #{manifest_json['app']['name']}")
  end

  def heroku_use
    creds = Conflux::Api::Bundles.new.team_user_app_tokens(@args[0])
    heroku_check = running_on_windows? ? Open3.capture3('where heroku') : Open3.capture3('which heroku')

    if heroku_check.first.empty?
      display [
        "The Heroku toolbelt needs to be installed before running this command.",
        "Go to https://toolbelt.heroku.com to install this toolbelt."
      ].join("\n")

      return
    end

    with_tty do
      system "heroku config:set CONFLUX_USER=#{creds['CONFLUX_USER']} CONFLUX_APP=#{creds['CONFLUX_APP']} -a #{@args[2]}"
      display "Successfully connected Heroku app '#{@args[2]}' to conflux bundle '#{@args[0]}'."
    end
  end

  def clone
    source_app_slug = @args[0]
    dest_app_name = @args[1]
    app_exists = Conflux::Api::Bundles.new.exists?(source_app_slug)

    if !app_exists['exists']
      display "No available bundle named '#{source_app_slug}'"
      return
    end

    tier_stage = ask_mult_choice_question(
      'Which tier do you want your cloned bundle to reside in?',
      ['Local Development', 'Cloud Development', 'Staging', 'Production']
    )

    display 'Cloning bundle...'

    Conflux::Api::Bundles.new.clone(app_exists['uuid'], dest_app_name, tier_stage)

    display "Successfully cloned bundle."
  end

  #--------------------------------- -------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'List all of your conflux bundles'
      VALID_ARGS = [ [] ]
    end

    module Current
      DESCRIPTION = 'Show which conflux bundle is connected to the current directory'
      VALID_ARGS = [ [] ]
    end

    module Use
      DESCRIPTION = 'Set which conflux bundle to use for the current directory'
      VALID_ARGS = [ ['BUNDLE'] ]
    end

    module HerokuUse
      DESCRIPTION = 'Set which conflux bundle to use for a specific heroku app'
      VALID_ARGS = [ ['BUNDLE', '-a', 'HEROKU_APP'] ]
    end

    module Clone
      DESCRIPTION = 'Clone a conflux bundle'
      VALID_ARGS = [ ['BUNDLE', 'NEW_BUNDLE'] ]
    end

  end

end