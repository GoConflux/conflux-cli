require 'conflux/helpers'
require 'conflux/langs'

module Conflux
  module Jobs
    extend self
    extend Conflux::Helpers

    NEW_LIBRARY = 'new_library'
    NEW_FILE = 'new_file'

    def execute_jobs(jobs_map)
      if jobs_map.empty?
        display "All jobs up to date."
        return
      end

      @succeeded_jobs = []

      jobs_map.each { |addon, jobs|
        display "Found #{jobs.count} new #{(jobs.count > 1 ? 'jobs' : 'job')} for #{addon}..."
        jobs.each { |job| execute_job(job) }
      }

      mark_succeeded_jobs_as_performed

      display "Done."
    end

    def execute_job(job)
      success = false
      action = job['action']
      asset = job['asset']

      case action
        when NEW_LIBRARY
          handle_new_library(asset)
          success = true

        when NEW_FILE
          success = true

      end

      @succeeded_jobs.push(job['id']) if success
    end

    def handle_new_library(asset)
      case asset['lang']
        when Conflux::Langs::RUBY
          Conflux::Langs.install_ruby_gem(asset['name'], version: asset['version'], add_to_gemfile: true)
      end
    end

    def mark_succeeded_jobs_as_performed
      File.open(conflux_jobs_path, 'a') do |f|
        input = @succeeded_jobs.join(',')
        input = ",#{input}" unless File.read(f).empty?
        f << input
      end
    end

  end
end