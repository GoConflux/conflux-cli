require 'conflux/api'
require 'conflux/auth'
require 'conflux/helpers'
require 'rest-client'

class Conflux::Api::AbstractApi
  include Conflux::Helpers

  def get(route, data: {}, headers: nil, auth_required: true, error_message: 'Error requesting Conflux data')
    ensure_authed if auth_required
    headers ||= netrc_headers

    route = data.empty? ? route : "#{route}?#{URI.encode_www_form(data)}"

    RestClient.get(url(route), headers) do |response|
      handle_json_response(response, error_message)
    end
  end

  def put(route, data: {}, headers: nil, auth_required: true, error_message: 'Error requesting Conflux data')
    ensure_authed if auth_required
    headers ||= netrc_headers

    RestClient.put(url(route), data, headers) do |response|
      handle_json_response(response, error_message)
    end
  end

  def post(route, data: {}, headers: nil, auth_required: true, error_message: 'Error requesting Conflux data')
    ensure_authed if auth_required
    headers ||= netrc_headers

    RestClient.post(url(route), data, headers) do |response|
      handle_json_response(response, error_message)
    end
  end

  def delete(route, data: {}, headers: nil, auth_required: true, error_message: 'Error requesting Conflux data')
    ensure_authed if auth_required
    headers ||= netrc_headers

    route = data.empty? ? route : "#{route}?#{URI.encode_www_form(data)}"

    RestClient.delete(url(route), headers) do |response|
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

end