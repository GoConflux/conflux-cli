require 'conflux/api/abstract_api'

class Conflux::Api::Addons < Conflux::Api::AbstractApi

  def extension
    '/addons'
  end

  def all
    get("#{extension}/all")
  end

  def for_app(args)
    get("#{extension}/for_app", data: { app_slug: args[1] }, headers: conditional_headers(args.empty?))
  end

  def plans(addon_slug)
    get("#{extension}/plans", data: { addon_slug: addon_slug })
  end

  def add(app_slug, addon_slug, plan)
    post('/app_addons', data: { app_slug: app_slug, addon_slug: addon_slug, plan: plan }, headers: conditional_headers(app_slug.nil?))
  end

end
