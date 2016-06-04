require 'conflux/command/abstract_command'
require_relative '../api/users'

class Conflux::Command::Apps < Conflux::Command::AbstractCommand

  def index
    apps_map = Conflux::Api::Users.new.apps

    apps_map.each { |team, apps|
      puts "\n#{team}:\n\n"
      apps.each { |slug| puts "  #{slug}" }
    }

    puts "\n"
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'List all of your conflux apps'
      VALID_ARGS = {}
    end

  end

end