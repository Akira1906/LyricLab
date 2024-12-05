# frozen_string_literal: true

require 'roda'
require 'yaml'
require 'figaro'
require 'rack/session'
require 'logger'
require 'rack-cache'

module LyricLab
  # Environment specific configuration
  class App < Roda
    plugin :environments

    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment:,
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load
    def self.config = Figaro.env

    use Rack::Session::Cookie, secret: config.SESSION_SECRET

    # Logger Setup
    @logger = Logger.new($stderr)
    class << self
      attr_reader :logger
    end

    # Debugging Tools
    configure :development, :test, :app_test do
      require 'pry'
    end
  end
end
