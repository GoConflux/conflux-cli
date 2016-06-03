require 'conflux/helpers'

module Conflux
  module Configs
    extend Conflux::Helpers
    extend self

    def write(configs)
      display 'Writing configs to conflux.yml...'

      File.open(conflux_yml_path, 'w+') do |f|
        f.write("\n# ----- Conflux Config Vars ----- \n")
        f.write("\n# Below are all Conflux configs that currently exist for this app.")
        f.write("\n# NOTE: Configs listed inside application.yml will always take priority over these.\n")

        configs.each { |config|
          key = config['name']

          if !ENV.key?(key)
            description = config['description'].nil? ? '' : "  # #{config['description']}"
            f.write("\n#{key}#{description}\n")
          end
        }
      end
    end

  end
end