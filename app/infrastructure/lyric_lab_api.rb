# frozen_string_literal: true
=begin
require_relative 'list_request'
require 'http'

module LyricLab
  module Gateway
    # Infrastructure to call LyricLab API
    class Api
      def initialize(config)
        @config = config
        @request = Request.new(config)
      end

      def alive?
        @request.get_root.success?
      end

      def recommendations_list
        @request.recommendations_list
      end

      def search_songs(search_query)
        @request.search_songs(search_query)
      end

      def record_song_recommendation(origin_id)
        @request.record_song_recommendation(origin_id)
      end

      def load_song_metadata(origin_id)
        @request.load_song_metadata(origin_id)
      end

      def load_vocabulary_song(origin_id)
        @request.load_vocabulary_song(origin_id)
      end

      # HTTP request transmitter
      class Request
        def initialize(config)
          @api_host = config.API_HOST
          @api_root = config.API_HOST + '/api/v1'
        end

        def get_root # rubocop:disable Naming/AccessorMethodName
          call_api('get')
        end

        def recommendations_list
          call_api('get', ['recommendations'])
        end

        def search_songs(search_query)
          call_api('get', ["search_results?search_query=#{search_query}"])
        end

        def record_song_recommendation(origin_id)
          call_api('post', ['songs', origin_id])
        end

        def load_song_metadata(origin_id)
          call_api('get', ['songs', origin_id])
        end

        def load_song_with_vocabulary(origin_id)
          call_api('get', ['vocabularies', origin_id])
        end

        private

        def params_str(params)
          params.map { |key, value| "#{key}=#{value}" }.join('&')
            .then { |str| str ? '?' + str : '' }
        end

        def call_api(method, resources = [], params = {})
          api_path = resources.empty? ? @api_host : @api_root
          url = [api_path, resources].flatten.join('/') + params_str(params)
          HTTP.headers('Accept' => 'application/json').send(method, url)
            .then { |http_response| Response.new(http_response) }
        rescue StandardError
          raise "Invalid URL request: #{url}"
        end

        # Decorates HTTP responses with success/error
        class Response < SimpleDelegator
          NotFound = Class.new(StandardError)

          SUCCESS_CODES = (200..299)

          def success?
            code.between?(SUCCESS_CODES.first, SUCCESS_CODES.last)
          end

          def message
            payload['message']
          end

          def payload
            body.to_s
          end
        end
      end
    end
  end
end
=end