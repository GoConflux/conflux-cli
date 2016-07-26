require 'conflux/api/abstract_api'

class Conflux::Api::Bundles < Conflux::Api::AbstractApi

  def extension
    '/apps'
  end

  def manifest(app_slug)
    get("#{extension}/manifest",
      data: { app_slug: app_slug },
      error_message: 'Error connecting to conflux bundle'
    )
  end

  def cost(args)
    get("#{extension}/cost",
      data: { app_slug: args[1] },
      headers: conditional_headers(args.empty?)
    )
  end

  def pull
    get('/pull',
      data: {
        past_jobs: (past_jobs.empty? ? nil : past_jobs.join(','))
      },
      headers: conditional_headers(true))
  end

  def configs(args)
    get("#{extension}/configs",
      data: { app_slug: args[1] },
      headers: conditional_headers(args.empty?)
    )
  end

  def team_user_app_tokens(app_slug)
    get("#{extension}/team_user_app_tokens",
      data: { app_slug: app_slug }
    )
  end

  def exists?(app_slug)
    get("#{extension}/exists",
      data: { app_slug: app_slug }
    )
  end

  def clone(source_app_uuid, dest_app_name, tier_stage)
    post("#{extension}/clone",
      data: {
        app_uuid: source_app_uuid,
        dest_app_name: dest_app_name,
        tier_stage: tier_stage
      }
    )
  end

end