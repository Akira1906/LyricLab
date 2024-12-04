# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Transaction to store project from Github API to database
    class FindSongsFromSearch
      include Dry::Transaction

      step :parse_search_string
      step :request_songs
      step :reify_songs

      private

      def parse_search_string(input)
        if input.success?
          search_string = input[:search_query]
          Success(search_string:)
        else
          Failure(input.errors.messages.first)
        end
      end

      def request_songs(input)
        result = Gateway::Api.new(LyricLab::App.config)
          .load_search_results(input[:search_string])

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace
        Failure('Cannot find songs right now; please try again later')
      end

      def reify_songs(songs_json)
        Representer::SearchResults.new(OpenStruct.new)
          .from_json(songs_json)
          .then { |songs| Success(songs) }
      rescue StandardError
        Failure('Error in the Search Results -- please try again')
      end
    end
  end
end
