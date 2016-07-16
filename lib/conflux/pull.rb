require 'conflux/api/bundles'
require 'conflux/configs'
require 'conflux/jobs'

module Conflux
  module Pull
    extend self

    def perform
      # Fetch for this conflux app:
      # (1) any new jobs that haven't run yet
      # (2) all config vars
      resp = Conflux::Api::Bundles.new.pull

      # Write the conflux config vars to conflux.yml
      Conflux::Configs::write(resp['configs'])

      # Execute the new jobs
      Conflux::Jobs::execute_jobs(resp['jobs'])
    end

  end
end