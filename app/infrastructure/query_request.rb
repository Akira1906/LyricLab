# frozen_string_literal: true

require 'base64'
require 'dry/monads'
require 'json'

module LyricLab
  module Gateway
    module Value
      # List request parser
      class Query
        include Dry::Monads::Result::Mixin

        # Use in client App to create params to send
        def self.to_encoded(query)
          Base64.urlsafe_encode64(query.to_json)
        end

        # Use in tests
        def self.to_request(query)
          Query.new('search_query' => to_encoded(query))
        end
      end
    end
  end
end
