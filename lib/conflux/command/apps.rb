require 'conflux/command/abstract_command'
require_relative '../api/users'
require_relative '../api/apps'
require 'fileutils'

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
    manifest_json = Conflux::Api::Apps.new.manifest(@args[0])

    # Create /.conflux/ folder if doesn't already exist
    FileUtils.mkdir_p(conflux_folder_path) if !File.exists?(conflux_folder_path)

    # Write this app info to a new manifest.json file for the user
    File.open(conflux_manifest_path, 'w+') do |f|
      f.write(JSON.pretty_generate(manifest_json))
    end

    display("Successfully connected project to conflux app: #{manifest_json['app']['name']}")
  end

  #----------------------------------------------------------------------------

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
      DESCRIPTION = 'Set which conflux app to use for your current directory'
      VALID_ARGS = [ ['APP'] ]
    end

  end

end