require 'rails/generators'

RAKE_PATH = 'lib/tasks/conflux.rake'

module Conflux
  module Generators
    class ConfluxGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def create_rake_file
        if !File.exists?(RAKE_PATH)
          copy_file('conflux.rake', RAKE_PATH)
        end
      end
    end
  end
end