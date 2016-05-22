require 'conflux/command'

class Conflux::Command::Base
  include Conflux::Helpers

  attr_reader :args
  attr_reader :options

  def self.namespace
    self.to_s.split("::").last.downcase
  end

  def initialize(args = [], options = {})
    @args = args
    @options = options
  end

end