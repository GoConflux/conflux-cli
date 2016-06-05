require 'conflux/command/abstract_command'

class Conflux::Command::App < Conflux::Command::AbstractCommand

  def index
    ensure_authed

    if File.exists?(conflux_manifest_path)
      manifest_json = JSON.parse(File.read(conflux_manifest_path)) rescue {}
      name = manifest_json['app']['name']

      if name.nil?
        reply_no_conflux_app
      else
        display "Directory currently connected to conflux app: #{name}"
      end
    else
      reply_no_conflux_app
    end
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'Shows which conflux app is connected to the current directory'
      VALID_ARGS = [ [] ]
    end

  end

end