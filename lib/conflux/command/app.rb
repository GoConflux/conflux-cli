require 'conflux/command/abstract_command'

class Conflux::Command::App < Conflux::Command::AbstractCommand

  def index
    # read straight from manifest.json and if not there tell user to run conflux init command to create connection
  end

  def switch

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

    module Switch
      DESCRIPTION = 'Change conflux apps for current directory'
    end

  end

end