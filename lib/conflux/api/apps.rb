require 'conflux/api/abstract_api'

class Conflux::Api::Apps < Conflux::Api::AbstractApi

  def extension
    '/apps'
  end

  def manifest(app_slug)
    get("#{extension}/manifest", data: { app_slug: app_slug })
  end

end