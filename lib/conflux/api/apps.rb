require 'conflux/api/abstract_api'

class Conflux::Api::Apps < Conflux::Api::AbstractApi

  def extension
    '/apps'
  end

  def list
    # get(extension)
    ['pulse-360-local', 'pulse-360-staging']
  end

  def manifest(app_slug)
    # get("#{extension}/manifest", data: { app_slug: app_slug })
    {
      'something' => 'mymanifest'
    }
  end

end