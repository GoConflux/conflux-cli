require 'conflux/api/abstract_api'

class Conflux::Api::Addons < Conflux::Api::AbstractApi

  def extension
    '/addons'
  end

  def list
    get("#{extension}/list")
  end

end