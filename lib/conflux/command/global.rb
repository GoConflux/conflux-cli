require 'conflux/command/abstract_command'
require 'conflux/api/apps'
require 'json'

class Conflux::Command::Global < Conflux::Command::AbstractCommand

  def init
    conflux_folder_path = "#{Dir.pwd}/.conflux/"
    conflux_manifest_path = File.join(conflux_folder_path, 'manifest.json')

    # if /.conflux/ folder doesn't exist yet
    if !File.exists?(conflux_folder_path)
      # Create the new directory
      Dir.mkdir(conflux_folder_path)
      # and add it to .gitignore
      File.open(File.join(Dir.pwd, '.gitignore'), 'a') do |f|
        f.puts "\n/.conflux/\n"
      end
    end

    # Tell the user if the manifest file already exists
    if File.exists?(conflux_manifest_path)
      manifest_json = JSON.parse(File.read(conflux_manifest_path)) rescue {}
      display("Connection already established for this directory with the Conflux app: #{manifest_json['name']}")
    else
      # if a Conflux user is properly authed
      if user_authed
        # Get list of all user's apps
        app_slugs = Conflux::Api::Apps.list

        # Ask user which app this project belongs to:
        selected_app_index = ask_mult_choice_question('Which Conflux app does this project belong to?', app_slugs)

        # Get the slug for the app the user selected
        selected_app_slug = app_slugs[selected_app_index]

        # Fetch manifest info for that selected app
        manifest_json = Conflux::Api::Apps.manifest(selected_app_slug)

        # Write this app info to a new manifest.json file for the user
        File.open(conflux_manifest_path, 'w+') do |f|
          f.write(JSON.pretty_generate(manifest_json))
        end

        display("Established new connection between this directory and the Conflux app: #{manifest_json['name']}")
      else
        display(format_with_bang("No Conflux user currently logged in.\nType `conflux login` to log in."))
      end
    end

  end

  def user_authed
    true
  end

end