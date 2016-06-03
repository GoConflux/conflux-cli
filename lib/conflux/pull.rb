require 'conflux/helpers'
require 'conflux/jobs'
require 'conflux/configs'
require 'conflux/api/apps'
require 'rest-client'

module Conflux
  module Pull
    extend Conflux::Helpers
    extend self

    def perform
      if File.exists?(conflux_manifest_path)
        manifest = JSON.parse(File.read(conflux_manifest_path)) rescue {}

        @manifest_creds = manifest['configs'] || {}

        if !@manifest_creds.key?('CONFLUX_USER') || !@manifest_creds.key?('CONFLUX_APP')
          reply_no_conflux_app
          return
        end

        pull_response = pull

        Conflux::Configs::write(pull_response['configs'])
        Conflux::Jobs::execute_jobs(pull_response['jobs'])
      else
        reply_no_conflux_app
      end

    end

    def pull
      job_ids = past_jobs
      endpoint = job_ids.empty? ? '/pull' : "/pull?past_jobs=#{job_ids.join(',')}"

      RestClient.get("#{host_url}#{endpoint}", pull_headers) do |response|
        if response.code == 200
          JSON.parse(response.body) rescue {}
        else
          error('Error making request')
        end
      end
    end

    def pull_headers
      {
        'Conflux-User' => @manifest_creds['CONFLUX_USER'],
        'Conflux-App' => @manifest_creds['CONFLUX_APP']
      }
    end

  end
end
