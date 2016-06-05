require 'conflux/api/apps'
require 'conflux/configs'
require 'conflux/jobs'

module Conflux
  module Pull
    extend self

    def perform
      resp = Conflux::Api::Apps.new.pull

      Conflux::Configs::write(resp['configs'])

      Conflux::Jobs::execute_jobs(resp['jobs'])
    end

  end
end