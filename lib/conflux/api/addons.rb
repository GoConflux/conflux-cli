require 'conflux/api/abstract_api'

class Conflux::Api::Addons < Conflux::Api::AbstractApi

  def extension
    '/addons'
  end

  def all
    get("#{extension}/all")
  end

  def for_app(app_slug)
    get("#{extension}/for_app", data: { app_slug: app_slug })
  end

end
