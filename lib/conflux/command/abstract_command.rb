require 'conflux/command'
require 'conflux/helpers'

class Conflux::Command::AbstractCommand
  include Conflux::Helpers

  attr_reader :args
  attr_reader :options

  def initialize(args = [], options = {})
    @args = args
    @options = options
  end

end