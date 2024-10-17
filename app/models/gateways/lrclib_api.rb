# frozen_string_literal: true

require 'http'

module LyricLab
  module Lrclib
    # library for lrclib API
    class Api
      def lyric_data(track_name, artist_name)
        Request.new.get(track_name, artist_name).parse
      end

      # Sends out HTTP requests to API
      class Request
        BASE_URL = 'https://lrclib.net/api/get'

        def get(track_name, artist_name)
          params = {
            track_name: track_name ,
            artist_name: artist_name
          }

          http_response = HTTP.get(BASE_URL, params: params)

          Response.new(http_response).tap do |response|
            raise(response.error) unless response.successful?
          end
        end
      end

      # Decorates HTTP responses from API with success/error reporting
      class Response < SimpleDelegator
        NotFound = Class.new(StandardError)

        HTTP_ERROR = {
          404 => NotFound
        }.freeze

        def successful?
          HTTP_ERROR.keys.none?(code)
        end

        def error
          HTTP_ERROR[code]
        end
      end
    end
  end
end
