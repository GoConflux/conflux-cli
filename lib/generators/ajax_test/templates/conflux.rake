require 'conflux'

namespace :command do
  desc 'Refetch config vars from Conflux'
  task :fetch do
    Conflux.fetch_and_cache_remote_configs
  end
end
