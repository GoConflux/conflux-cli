require 'conflux/helpers'
require 'conflux/langs'
require 'open3'
require 'fileutils'

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
          handle_new_file(asset)
      end

      @succeeded_jobs.push(job['id']) if success
    end

    def handle_new_library(asset)
      case asset['lang']
        when Conflux::Langs::RUBY
          Conflux::Langs.install_ruby_gem(asset['name'], version: asset['version'], add_to_gemfile: true)
      end
    end

    def handle_new_file(asset)
      dest_path = asset['dest_path']

      dest_file = File.join(Dir.pwd, dest_path)

      return if File.exists?(dest_file)

      FileUtils.mkdir_p(File.dirname(dest_file))

      url = "#{s3_url}/#{asset['file']}"

      wget_check = Open3.capture3('which wget')

      display "Creating file \"#{dest_path}\""

      command = wget_check.first.empty? ?
        "curl -s #{url} >> #{dest_file}" :
        "wget -qO- #{url} >> #{dest_file}"

      with_tty do
        system command
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