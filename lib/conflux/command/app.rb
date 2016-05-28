require 'conflux/command/abstract_command'

class Conflux::Command::App < Conflux::Command::AbstractCommand

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
      VALID_ARGS = {
        '-t' => {
          description: 'My T description'
        },
        '-p' => {
          description: 'My P description'
        }
      }
    end

    module Change
      DESCRIPTION = 'Change conflux apps for current directory'
      VALID_ARGS = {}
    end

  end

end