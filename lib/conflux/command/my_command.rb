require 'conflux/command/base'

class Conflux::Command::MyCommand < Conflux::Command::Base

  def my_method
    display 'Heard my method'
  end

end