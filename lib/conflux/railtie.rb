require 'rails'

module Conflux
  class Railtie < Rails::Railtie
    initializer 'railtie.configure_rails_initialization' do
      Conflux.fetch_and_cache_remote_configs
      Conflux.create_rake_file
    end
  end
end