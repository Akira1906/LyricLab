# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Transaction to store project from Github API to database
    class LoadSongHistory
      include Dry::Transaction

      step :get_songs
      step :reify_songs

      def get_songs(ids)
        result = Gateway::Api.new(LyricLab::App.config)
          .load_songs(ids.join('-'))

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        puts e.inspect
        puts e.backtrace
        Failure('Cannot find songs right now; please try again later')
      end

      def reify_recommendations(songs_json)
        Representer::SearchResults.new(OpenStruct.new)
          .from_json(songs_json)
          .then { |songs| Success(songs) }
      rescue StandardError
        Failure('Error in the Load Songs -- please try again')
      end
    end
  end
end

