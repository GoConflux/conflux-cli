require 'conflux/api/abstract_api'

class Conflux::Api::Apps < Conflux::Api::AbstractApi

  def extension
    '/apps'
  end

  def manifest(app_slug)
    get("#{extension}/manifest", data: { app_slug: app_slug }, error_message: 'Error connecting to conflux app')
  end

  def cost(args)
    get("#{extension}/cost", data: { app_slug: args[1] }, headers: conditional_headers(args.empty?))
  end

  def pull
    get('/pull', data: { past_jobs: (past_jobs.empty? ? nil : past_jobs.join(',')) }, headers: conditional_headers(true))
  end

end