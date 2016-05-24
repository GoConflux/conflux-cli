require 'conflux/api/abstract_api'

class Conflux::Api::Users < Conflux::Api::AbstractApi

  def login(email, password, team_slug: nil)
    if team_slug.nil?
      {
        'team_slugs' => [
          'reflektive',
          'other_company'
        ]
      }
    else
      {
        'user_token' => '123456789',
        'team' => 'Reflektive'
      }
    end
  end

end