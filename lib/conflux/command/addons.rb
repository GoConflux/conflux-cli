require 'conflux/command/abstract_command'
require_relative '../api/addons'
require_relative '../pull'

class Conflux::Command::Addons < Conflux::Command::AbstractCommand

  def index
    addons = Conflux::Api::Addons.new.for_app(@args)

    if (addons || []).length == 0
      puts 'No addons exist yet for this app.'
      puts 'See how to provision add-ons with "conflux addons:add --help"'
      return
    end

    puts to_table(addons, ['slug', 'name', 'plan', 'cost'])
  end

  def all
    addons = Conflux::Api::Addons.new.all
    puts to_table(addons, ['slug', 'name', 'description'])
    puts "\nSee plans with conflux addons:plans ADDON\n\n"
  end

  def add
    addon_slug, plan = @args.first.split(':')
    app_slug = @args[2]

    resp = Conflux::Api::Addons.new.add(app_slug, addon_slug, plan)

    display "Successfully added #{addon_slug} to #{resp['app_slug'] || app_slug}."

    Conflux::Pull.perform
  end

  def remove
    addon_slug, plan = @args.first.split(':')
    app_slug = @args[2]

    resp = Conflux::Api::Addons.new.remove(app_slug, addon_slug, plan)

    display "Successfully removed #{addon_slug} from #{resp['app_slug'] || app_slug}."

    Conflux::Pull.perform
  end

  def plans
    plans_info = Conflux::Api::Addons.new.plans(@args[0])
    puts to_table(plans_info, ['slug', 'name', 'cost'])
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'List addons for a specific conflux bundle'
      VALID_ARGS = [ [], ['-b', 'BUNDLE'] ]
      NO_BUNDLE_MEANS_LOCAL = true
    end

    module All
      DESCRIPTION = 'List all available addons'
      VALID_ARGS = [ [] ]
    end

    module Add
      DESCRIPTION = 'Add an addon to a conflux bundle'
      VALID_ARGS = [ ['ADDON'], ['ADDON', '-b', 'BUNDLE'] ]
      NO_BUNDLE_MEANS_LOCAL = true
    end

    module Remove
      DESCRIPTION = 'Remove an addon from a conflux bundle'
      VALID_ARGS = [ ['ADDON'], ['ADDON', '-b', 'BUNDLE'] ]
      NO_BUNDLE_MEANS_LOCAL = true
    end

    module Plans
      DESCRIPTION = 'List all plans for an addon'
      VALID_ARGS = [ ['ADDON'] ]
    end

  end

end