require 'conflux/api/abstract_api'

module Conflux
  module Api
    module Apps

      extend Conflux::Api::AbstractApi

      def self.list
        [
          'local-dev-1',
          'local-dev-2',
          'my-other-dev-app'
        ]
      end

      def self.manifest(app_slug)
        {
          'name' => 'local-dev-1',
          'url' => 'http://conflux-user.herokuapp.com/reflektive/pulse-360-web/local-dev-1',
          'config' => {
            'CONFLUX_USER' => 'ABCDEFGH',
            'CONFLUX_APP' => '123456789'
          }
        }
      end

    end
  end
end