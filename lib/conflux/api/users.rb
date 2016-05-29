require 'conflux/api/abstract_api'

class Conflux::Api::Users < Conflux::Api::AbstractApi

  def extension
    '/users'
  end

  def login(email, password)
    resp = post(
      "#{extension}/login",
      data: {
        email: email,
        password: password
      },
      auth_required: false,
      error_message: 'Authentication failed'
    )

    resp['user_token']
  end

  def apps
    get("#{extension}/apps")
  end

end