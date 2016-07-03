require 'conflux/helpers'
require 'conflux/langs'
require 'open3'
require 'fileutils'

module Conflux
  module Jobs
    extend self
    extend Conflux::Helpers

    # Valid job types
    NEW_LIBRARY = 'new_library'
    NEW_FILE = 'new_file'

    # Run jobs pulled from `conflux pull`
    def execute_jobs(jobs_map)
      # if there aren't any new jobs, say so.
      if jobs_map.empty?
        display "All jobs up to date."
        return
      end

      @succeeded_jobs = []

      # Run jobs one addon at a time
      jobs_map.each { |addon, jobs|
        display "Found #{jobs.count} new #{(jobs.count > 1 ? 'jobs' : 'job')} for #{addon}..."
        jobs.each { |job| execute_job(job) }
      }

      # Add the ids of the jobs that succeeded to the jobs.txt file
      mark_succeeded_jobs_as_performed

      display "Done."
    end

    # Run a job. Currently there are only two kinds of jobs that can be ran:
    # (1) Install a client library (ruby gem)
    # (2) Add a new file to the project
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

    # Install client library based on which language the project is.
    # Currently only Ruby projects are supported.
    def handle_new_library(asset)
      case asset['lang']
        when Conflux::Langs::RUBY
          Conflux::Langs.install_ruby_gem(asset['name'], version: asset['version'], add_to_gemfile: true)
      end
    end

    # Add a new file (via public url) to the project if it doesn't already exist.
    def handle_new_file(asset)
      dest_path = asset['path']

      dest_file = File.join(Dir.pwd, dest_path)

      # Return if file already exists
      if File.exists?(dest_file)
        display "Not creating file: \"#{dest_path}\" --> File already exists."
        return
      end

      # Ensure all parent directories of the file exist
      FileUtils.mkdir_p(File.dirname(dest_file))

      # Create url for file from Conflux's S3 --> asset['contents'] should start with '/'
      url = "#{s3_url}#{asset['contents']}"

      # Check if `wget` is installed
      wget_check = Open3.capture3('which wget')

      display "Creating file: \"#{dest_path}\""

      # Choose command that will be used to fetch file contents based on if
      # `wget` is intalled. If `wget` isn't installed, default to using `curl`.
      command = wget_check.first.empty? ?
        "curl -s #{url} >> #{dest_file}" :
        "wget -qO- #{url} >> #{dest_file}"

      with_tty do
        system command
      end
    end

    # Append job id's to the .conflux/jobs.txt file to keep track of which jobs
    # have already ran.
    def mark_succeeded_jobs_as_performed
      File.open(conflux_jobs_path, 'a') do |f|
        input = @succeeded_jobs.join(',')
        input = ",#{input}" unless File.read(f).empty?
        f << input
      end
    end

  end
end