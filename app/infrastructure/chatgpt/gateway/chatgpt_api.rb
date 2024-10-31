# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'yaml'
require 'delegate'
require 'http'
require 'openai'

module LyricLab
  # Library for OpenAI API
  class OpenAI
    def initialize(api_key)
      @api_key = api_key
    end

    def chat_response(messages)
      Request.new(@api_key).chat(messages)
    end

    # Sends out HTTP requests to OpenAI
    class Request
      API_URL = 'https://api.openai.com/v1/chat/completions'

      def initialize(api_key)
        @api_key = api_key
      end

      def chat(messages)
        post(API_URL, { model: 'gpt-3.5-turbo', messages: messages })
      end

      puts "Loaded API Key: #{@api_key}"

      def post(url, payload)
        body = payload
        http_response = RestClient::Request.execute(
            method: :post,
            url: url,
            payload: body.to_json,
            headers: {
              Authorization: "Bearer #{@api_key}",
              content_type: :json,
              accept: :json
            }
          )

        Response.new(http_response).tap do |response|
            raise(response.error, "HTTP #{response.code}: #{response.body}") unless response.successful?
          end.parse
        rescue StandardError => e
          puts "Error during request: #{e.message}"
          nil
      end
    end

    # Decorates HTTP responses from OpenAI with success/error reporting
    class Response < SimpleDelegator
      BadRequest = Class.new(StandardError)
      Unauthorized = Class.new(StandardError)
      NotFound = Class.new(StandardError)

      HTTP_ERROR = {
        400 => BadRequest,
        401 => Unauthorized,
        404 => NotFound
      }.freeze

      def successful?
        HTTP_ERROR.keys.none?(code)
      end

      def error
        HTTP_ERROR[code]
      end

      def parse
        JSON.parse(__getobj__.body)['choices'][0]['message']['content']
      end
    end
  end
end

# secret.yaml for api
secrets_path = File.expand_path('../../../../../config/secrets.yml', __FILE__)
secrets = YAML.load_file(secrets_path)
API_KEY = secrets['openai_api_key']


api_client = LyricLab::OpenAI.new(API_KEY)

# example
messages = [
  { role: 'user', content: '告五人，好不容易' }
]

response = api_client.chat_response(messages)

if response
  puts "response: #{response}"

  File.open('spec/fixtures/chat_response.yml', 'w') do |file|
    file.write({ response: response }.to_yaml)
  end
else
  puts 'something wrong'
end

