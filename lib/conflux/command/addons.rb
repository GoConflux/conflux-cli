require 'conflux/command/abstract_command'
require_relative '../api/addons'
require_relative '../pull'

class Conflux::Command::Addons < Conflux::Command::AbstractCommand

  def index
    list
  end

  def list
    addons = Conflux::Api::Addons.new.list
    puts to_table(addons, ['name', 'slug', 'description'])
  end

  def add
    if ![1, 3].include?(@args.length) || (@args.length == 3 && @args[1] != '-a')
      # return command help
      return
    end

    addon_slug, plan = @args.first.split(':')
    app_slug = @args[2]

    if app_slug.nil?
      if File.exists?(conflux_manifest_path)
        manifest = JSON.parse(File.read(conflux_manifest_path)) rescue {}

        @manifest_creds = manifest['configs'] || {}

        if !@manifest_creds.key?('CONFLUX_USER') || !@manifest_creds.key?('CONFLUX_APP')
          reply_no_conflux_app
          return
        end

        headers = {
          'Conflux-User' => @manifest_creds['CONFLUX_USER'],
          'Conflux-App' => @manifest_creds['CONFLUX_APP']
        }
      else
        reply_no_conflux_app
      end
    else
      ensure_authed
      headers = { 'Conflux-User' => @password }
    end

    data = {
      app_slug: app_slug,
      addon_slug: addon_slug,
      plan: plan
    }

    RestClient.post("#{host_url}/app_addons", data, headers) do |response|
      if response.code == 200
        body = JSON.parse(response.body) rescue {}
        display "Successfully added #{addon_slug} to #{body['app_slug'] || app_slug}."
        Conflux::Pull.perform
      else
        error "Error adding #{addon_slug} as an addon."
      end
    end
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'Lists all conflux addons'
      VALID_ARGS = {}
    end

    module List
      DESCRIPTION = 'Lists all available conflux addons'
      VALID_ARGS = {}
    end

    module Add
      DESCRIPTION = 'Adds and addon to a conflux app'
    end

  end

end