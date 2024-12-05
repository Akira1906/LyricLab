# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Transaction to store project from Github API to database
    class LoadVocabulary
      include Dry::Transaction

      step :populate_vocabulary
      step :reify_vocabulary

      MSG_NO_VOCABULARY = 'Failed to generate vocabulary.'
      MSG_REIFY_FAILED = 'Error in the LoadVocabulary.'

      private

      GPT_API_KEY = LyricLab::App.config.GPT_API_KEY

      def populate_vocabulary(origin_id)
        result = Gateway::Api.new(LyricLab::App.config)
          .load_vocabulary(origin_id)

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace.join("\n")
        Failure(MSG_NO_VOCABULARY)
      end

      def reify_vocabulary(songs_json)
        Representer::Song.new(OpenStruct.new)
          .from_json(songs_json)
          .then { |songs| Success(songs) }
      rescue StandardError
        Failure(MSG_REIFY_FAILED)
      end
    end
  end
end
