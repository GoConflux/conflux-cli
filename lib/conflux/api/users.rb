require 'conflux/api/abstract_api'

class Conflux::Api::Users < Conflux::Api::AbstractApi

  def login(email, password, team_slug: nil)
    post('/login', {
      email: email,
      password: password,
      team_slug: team_slug
    })
  end

end