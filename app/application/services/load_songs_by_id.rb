# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Retrieves array of songs entities by ids
    class LoadSongsById
      include Dry::Transaction

      MSG_NO_SONGS = 'There are no songs to be loaded.'
      MSG_LOAD_FAILURE = 'Cannot load songs by id right now.'
      MSG_REIFY_FAILED = 'Error in LoadSongsById.'

      step :get_songs
      step :reify_songs

      def get_songs(ids)
        return Failure(MSG_NO_SONGS) if ids.empty?
        result = Gateway::Api.new(LyricLab::App.config)
          .load_songs(ids.join('-'))
        Failure(MSG_NO_SONGS) if result.failure?
        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace.join("\n")
        Failure(MSG_LOAD_FAILURE)
      end

      def reify_songs(songs_json)
        Representer::SearchResults.new(OpenStruct.new)
          .from_json(songs_json)
          .then { |songs| Success(songs) }
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace.join("\n")
        Failure(MSG_REIFY_FAILED)
      end
    end
  end
end
