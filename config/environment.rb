# frozen_string_literal: true

require 'roda'
require 'yaml'
require 'figaro'
require 'sequel'
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

    configure :development, :test do
      require 'pry'; # for breakpoints
      ENV['DATABASE_URL'] = "sqlite://#{config.DB_FILENAME}"
    end

    configure :development do
      use Rack::Cache,
      verbose: true,
      metastore: 'file:_cache/rack/meta',
      entitystore: 'file:_cache/rack/body'
    end

    # Database Setup
    @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    def self.db = @db # rubocop:disable Style/TrivialAccessors

    # Logger Setup
    @logger = Logger.new($stderr)
    class << self
      attr_reader :logger
    end

    # Word List Setup (load into memory)
    # word_list[[characters, pinyin, word_type], ...]
    @word_list = YAML.load_file('files/mandarin_word_list.yml')
    @merged_word_list = @word_list.values.flatten(1)

    # [beginner, novice1, novice2, level1, level2, level3, level4, level5]
    @list_indexes = [0]
    current_index = 0

    @word_list.each_value do |list|
      current_index += list.size
      @list_indexes << current_index
    end

    @merged_word_list = @merged_word_list.map! { |word| word[0] }
    class << self
      attr_reader :merged_word_list
    end
    def self.list_indexes = @list_indexes # rubocop:disable Style/TrivialAccessors
    def self.word_list = @word_list # rubocop:disable Style/TrivialAccessors
  end
end
