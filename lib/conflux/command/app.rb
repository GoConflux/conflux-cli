require 'conflux/command/abstract_command'

class Conflux::Command::App < Conflux::Command::AbstractCommand

  def index
    tell_user_to_run_init = lambda {
      display "Directory not currently connected to a conflux app.\n"\
        "Run \"conflux init\" to a establish a connection with one of your apps."
    }

    if File.exists?(conflux_manifest_path)
      manifest_json = JSON.parse(File.read(conflux_manifest_path)) rescue {}
      name = manifest_json['app']['name']

      if name.nil?
        tell_user_to_run_init.call
      else
        display "Directory currently connected to conflux app: #{name}"
      end
    else
      tell_user_to_run_init.call
    end
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'Shows conflux app info for current directory'
      VALID_ARGS = {}
    end

  end

end