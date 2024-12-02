# frozen_string_literal: true

require_relative 'query_request'
require 'http'

module LyricLab
  module Gateway
    # Infrastructure to call CodePraise API
    class Api
      def initialize(config)
        @config = config
        @request = Request.new(@config)
      end

      def alive?
        @request.get_root.success?
      end

      def list_recommendations
        @request.list_recommendations
      end

      def load_search_results(search_query)
        @request.load_search_results(search_query)
      end

      def load_song(origin_id)
        @request.load_song(origin_id)
      end

      def load_vocabulary(origin_id)
        @request.load_vocabulary(origin_id)
      end

      def record_recommendation(origin_id)
        @request.record_recommendation(origin_id)
      end

      def load_songs(origin_ids)
        @request.load_songs(origin_ids)
      end

      # HTTP request transmitter
      class Request
        def initialize(config)
          @api_host = config.API_HOST
          @api_root = "#{config.API_HOST}/api/v1"
        end

        def get_root # rubocop:disable Naming/AccessorMethodName
          call_api('get')
        end

        def list_recommendations
          call_api('get', ['recommendations'])
        end

        def load_search_results(query)
          call_api('get', ['search_results'], 'search_query' => Value::Query.to_encoded(query))
        end

        def load_song(origin_id)
          call_api('get', ['songs', origin_id])
        end

        def load_vocabulary(origin_id)
          call_api('get', ['vocabularies', origin_id])
        end

        def record_recommendation(origin_id)
          call_api('post', ['songs', origin_id])
        end

        def load_songs(origin_ids)
          call_api('get', ['search_results', origin_ids])
        end

        private

        def params_str(params)
          params.map { |key, value| "#{key}=#{value}" }.join('&')
            .then { |str| str ? '?' + str : '' }
        end

        def call_api(method, resources = [], params = {})
          api_path = resources.empty? ? @api_host : @api_root
          url = [api_path, resources].flatten.join('/') + params_str(params)
          puts url
          HTTP.headers('Accept' => 'application/json').send(method, url)
            .then { |http_response| Response.new(http_response) }
        rescue StandardError
          raise "Invalid URL request: #{url}"
        end
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
