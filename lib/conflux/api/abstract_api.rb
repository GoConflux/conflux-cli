require 'conflux/api'
require 'conflux/auth'
require 'conflux/helpers'
require 'rest-client'

class Conflux::Api::AbstractApi
  include Conflux::Helpers

  def ensure_authed
    @credentials = Conflux::Auth.read_credentials

    if @credentials.nil?
      error("Permission Denied. Run `conflux login` to login to your Conflux account.")
    end

    @email = @credentials[0]
    @password = @credentials[1]
  end

  def get(route, data: {}, auth_required: true, error_message: 'Error requesting Conflux data')
    ensure_authed if auth_required

    route = data.empty? ? route : "#{route}?#{URI.encode_www_form(data)}"

    RestClient.get(url(route), auth_header) do |response|
      handle_json_response(response, error_message)
    end
  end

  def put(route, data: {}, auth_required: true, error_message: 'Error requesting Conflux data')
    ensure_authed if auth_required

    RestClient.put(url(route), data, auth_header) do |response|
      handle_json_response(response, error_message)
    end
  end

  def post(route, data: {}, auth_required: true, error_message: 'Error requesting Conflux data')
    ensure_authed if auth_required

    RestClient.post(url(route), data, auth_header) do |response|
      handle_json_response(response, error_message)
    end
  end

  def handle_json_response(response, error_message)
    if response.code == 200
      JSON.parse(response.body) rescue {}
    else
      error(error_message)
    end
  end

  def auth_header
    @password ? { 'Conflux-User' => @password } : {}
  end

  def url(route)
    "#{host_url}#{route}"
  end

end