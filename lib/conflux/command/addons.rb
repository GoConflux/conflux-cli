require 'conflux/command/abstract_command'
require_relative '../api/addons'
require_relative '../pull'

class Conflux::Command::Addons < Conflux::Command::AbstractCommand

  def index
    app_slug = @args[1]
    headers = conditional_headers(@args.empty?)
    endpoint = app_slug.nil? ? '/for_app' : "/for_app?app_slug=#{app_slug}"

    RestClient.get("#{host_url}/addons#{endpoint}", headers) do |response|
      if response.code == 200
        addons = JSON.parse(response.body) rescue {}
        puts to_table(addons, ['slug', 'name', 'plan', 'cost'])
      else
        error('Error making request')
      end
    end
  end

  def all
    addons = Conflux::Api::Addons.new.all
    puts to_table(addons, ['slug', 'name', 'description'])
    puts "\nSee plans with conflux addons:plans ADDON\n\n"
  end

  def add
    addon_slug, plan = @args.first.split(':')
    app_slug = @args[2]

    headers = conditional_headers(app_slug.nil?)

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

  def plans
    plans_info = Conflux::Api::Addons.new.plans(@args[0])
    puts to_table(plans_info, ['slug', 'name', 'cost'])
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'List addons for a specific conflux app'
      VALID_ARGS = [ [], ['-a', 'APP'] ]
      NO_APP_MEANS_LOCAL = true
    end

    module All
      DESCRIPTION = 'List all available addons'
      VALID_ARGS = [ [] ]
    end

    module Add
      DESCRIPTION = 'Add an addon to a conflux app'
      VALID_ARGS = [ ['ADDON'], ['ADDON', '-a', 'APP'] ]
      NO_APP_MEANS_LOCAL = true
    end

    module Plans
      DESCRIPTION = 'List all plans for an addon'
      VALID_ARGS = [ ['ADDON'] ]
    end

  end

end