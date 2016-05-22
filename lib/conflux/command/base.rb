require 'conflux/command'
require 'conflux/helpers'

class Conflux::Command::Base
  include Conflux::Helpers

  attr_reader :args
  attr_reader :options

  def initialize(args = [], options = {})
    @args = args
    @options = options
  end

end