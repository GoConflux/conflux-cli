require 'conflux/api/abstract_api'

class Conflux::Api::Users < Conflux::Api::AbstractApi

  def login(email, password)
    resp = post(
      '/users/login',
      data: {
        email: email,
        password: password
      },
      auth_required: false,
      error_message: 'Authentication failed'
    )

    resp['user_token']
  end

end