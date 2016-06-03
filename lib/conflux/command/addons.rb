require 'conflux/command/abstract_command'
require_relative '../api/addons'

class Conflux::Command::Addons < Conflux::Command::AbstractCommand

  def index
    list
  end

  def list
    addons = Conflux::Api::Addons.new.list
    puts to_table(addons, ['name', 'slug', 'description'])
  end

  def add
    display 'heard conflux addons:add'
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
      VALID_ARGS = {}
    end

  end

end