require 'conflux/command/abstract_command'

class Conflux::Command::App < Conflux::Command::AbstractCommand

  module Descriptions
    INDEX = 'My Index Description'
    CHANGE = 'My Index Description'
  end

  def index
    display 'HEARD APP INDEX'
  end

  def change
    display 'HEARD APP CHANGE'
  end


  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'Shows conflux app info for current directory'
      VALID_ARGS = []
    end

    module Change
      DESCRIPTION = 'Change conflux apps for current directory'
      VALID_ARGS = []
    end

  end

end