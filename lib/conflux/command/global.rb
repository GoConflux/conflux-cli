require 'conflux/command/base'

class Conflux::Command::Global < Conflux::Command::Base

  def update
    display "Heard update with args #{@args}"
  end

end