require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'yaml'
require 'conflux/version'
require 'conflux/railtie'
require 'generators/conflux/conflux_generator'

API_KEY_NAME = 'CONFLUX_API_KEY'
HOST_URL = 'http://conflux-dev.herokuapp.com'
CUSTOM_HEADER = 'Conflux-API-Token'
YAML_HEADER = '# Conflux Config Vars'

module Conflux
  extend self

  def fetch_and_cache_remote_configs
    get_api_token_from_app_configs
    fetch_remote_configs if @token.present?
  end

  def get_api_token_from_app_configs
    @app_configs = YAML::load_file(File.join(Rails.root, 'config', 'application.yml')) || {}
    @token = @app_configs[API_KEY_NAME] || (@app_configs[Rails.env] || {})[API_KEY_NAME]
  end

  def fetch_remote_configs
    uri = URI.parse("#{HOST_URL}/keys")
    http = Net::HTTP.new(uri.host, uri.port)
    # http.use_ssl = true
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    request.add_field(CUSTOM_HEADER, @token)
    @response = http.request(request)
    set_config_vars_from_remote_configs
  end

  def set_config_vars_from_remote_configs
    remote_configs = JSON.parse(@response.body) rescue {}
    conflux_yml = File.open(File.join(Rails.root, 'config', 'conflux.yml'), 'w+')
    conflux_yml.write("\n#{YAML_HEADER}\n\n")

    remote_configs.each { |key, value|
      if key_already_set?(key)
        line = "# #{key}: \"#{value}\"  #Overwritten\n"
      else
        line = "#{key}: \"#{value}\"\n"
        ENV[key] = value
      end

      conflux_yml.write(line)
    }

    conflux_yml.close
  end

  def key_already_set?(key)
    ENV.key?(key) || @app_configs.include?(key) || (@app_configs[Rails.env] || {}).include?(key)
  end

  def create_rake_file
    Conflux::Generators::ConfluxGenerator.new.create_rake_file
  end

end
