require 'conflux/helpers'

module Conflux
  module Configs
    extend Conflux::Helpers
    extend self

    # Write pulled config vars from conflux to the .conflux/conflux.yml file
    # The conflux ruby gem does this as well, but the gem does this on boot by hooking into a railtie. This one
    # just gets executed whenever `conflux pull` is called from the CLI.
    def write(configs_map)
      display 'Writing configs to conflux.yml...'

      File.open(conflux_yml_path, 'w+') do |f|
        f.write(yaml_header)

        # configs_map has addon names for keys and arrays of config vars for those addons (respectively) as its values.
        # This yaml file will therefore group the conflux config vars by addon
        configs_map.each { |addon_name, configs|
          f.write("\n\n# #{addon_name}") if !configs.empty?

          configs.each { |config|
            key = config['name']

            if !ENV.key?(key)
              description = config['description'].nil? ? '' : "  # #{config['description']}"
              f.write("\n#{key}#{description}")
            end
          }
        }
      end
    end

    def yaml_header
      "\n# CONFLUX CONFIG VARS:\n\n" \
    "# All config vars seen here are in use and pulled from Conflux.\n" \
    "# If any are ever overwritten, they will be marked with \"Overwritten\"\n" \
    "# If you ever wish to overwrite any of these, do so inside of a config/application.yml file."
    end

  end
end