# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Retrieves array of all listed project entities
    class LoadSearchResults
      include Dry::Transaction

      step :get_songs
      step :reify_songs

      def get_songs(ids)
        result = Gateway::Api.new(LyricLab::App.config)
          .load_songs(ids.join('-'))
        puts "LoadSearchResults: #{result}"
        Failure('There are no songs to be loaded') if result.failure?
        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace.join("\n")
        Failure('Cannot LoadSearchResults right now')
      end

      def reify_songs(songs_json)
        Representer::SearchResults.new(OpenStruct.new)
          .from_json(songs_json)
          .then { |songs| Success(songs) }
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace.join("\n")
        Failure('Error in LoadSearchResults')
      end
    end
  end
end
