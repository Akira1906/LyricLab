# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Transaction to store project from Github API to database
    class LoadVocabulary
      include Dry::Transaction

      GPT_API_KEY = LyricLab::App.config.GPT_API_KEY

      step :populate_vocabulary
      step :reify_vocabulary

      private

      def populate_vocabulary(origin_id)
        result = Gateway::Api.new(LyricLab::App.config)
          .load_vocabulary(origin_id)

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        puts e.inspect
        puts e.backtrace
        Failure('Cannot create vocabularies right now; please try again later')
      end

      def reify_vocabulary(songs_json)
        Representer::Song.new(OpenStruct.new)
          .from_json(songs_json)
          .then { |songs| Success(songs) }
      rescue StandardError
        Failure('Error in the Song -- please try again')
      end
    end
  end
end
