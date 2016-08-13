require 'conflux/command/abstract_command'
require_relative '../api/services'
require_relative '../pull'

class Conflux::Command::Services < Conflux::Command::AbstractCommand

  def index
    addons = Conflux::Api::Services.new.for_app(@args)

    if (addons || []).length == 0
      puts 'No services exist yet for this app.'
      puts 'See how to provision services with "conflux services:add --help"'
      return
    end

    puts to_table(addons, ['slug', 'name', 'scope', 'plan', 'cost'])
  end

  def all
    addons = Conflux::Api::Services.new.all
    puts to_table(addons, ['slug', 'name', 'description'])
    puts "\nSee plans with conflux services:plans SERVICE\n\n"
  end

  def add
    addon_slug, plan = @args.first.split(':')
    app_slug = @args[2]
    scope = (@args.last == '--me') ? 1 : 0

    resp = Conflux::Api::Services.new.add(app_slug, addon_slug, plan, scope)

    if !!resp['plan_disabled']
      display "Plan not currently available. See 'conflux services:plans #{addon_slug}' for a list of available plans."
    elsif !!resp['addon_already_exists']
      display "#{addon_slug} already exists as a #{scope == 1 ? 'personal' : 'shared'} service for this bundle."
    else
      display "Successfully added #{addon_slug} to #{resp['app_slug'] || app_slug}#{scope == 1 ? ' as personal service' : ''}."
      Conflux::Pull.perform if app_slug.nil?
    end
  end

  def remove
    addon_slug, plan = @args.first.split(':')
    app_slug = @args[2]

    resp = Conflux::Api::Services.new.remove(app_slug, addon_slug, plan)

    display "Successfully removed #{addon_slug} from #{resp['app_slug'] || app_slug}."

    Conflux::Pull.perform if app_slug.nil?
  end

  def plans
    plans_info = Conflux::Api::Services.new.plans(@args[0])
    puts to_table(plans_info, ['slug', 'name', 'cost', 'status'])
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'List services for a specific conflux bundle'
      VALID_ARGS = [ [], ['-b', 'BUNDLE'] ]
      NO_BUNDLE_MEANS_LOCAL = true
    end

    module All
      DESCRIPTION = 'List all available services'
      VALID_ARGS = [ [] ]
    end

    module Add
      DESCRIPTION = 'Add a service to a conflux bundle'
      VALID_ARGS = [ ['SERVICE'], ['SERVICE', '--me'], ['SERVICE', '-b', 'BUNDLE'], ['SERVICE', '-b', 'BUNDLE', '--me'] ]
      NO_BUNDLE_MEANS_LOCAL = true
    end

    module Remove
      DESCRIPTION = 'Remove a service from a conflux bundle'
      VALID_ARGS = [ ['SERVICE'], ['SERVICE', '-b', 'BUNDLE'] ]
      NO_BUNDLE_MEANS_LOCAL = true
    end

    module Plans
      DESCRIPTION = 'List all plans for a service'
      VALID_ARGS = [ ['SERVICE'] ]
    end

  end

end