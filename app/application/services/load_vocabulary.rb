# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Transaction to store project from Github API to database
    class LoadVocabulary
      include Dry::Transaction

      step :load_vocabulary
      step :reify_vocabulary

      MSG_NO_VOCABULARY = 'Can\' load vocabulary.'
      MSG_REIFY_FAILED = 'Failed to reify vocabulary.'

      private

      GPT_API_KEY = LyricLab::App.config.GPT_API_KEY

      def load_vocabulary(input)
        input[:response] = Gateway::Api.new(LyricLab::App.config)
          .load_vocabulary(input[:origin_id])

        input[:response].success? ? Success(input) : Failure(input[:response].message)
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace.join("\n")
        Failure(MSG_NO_VOCABULARY)
      end

      def reify_vocabulary(input)
        # puts "input[:response].payload: #{input[:response].payload}"
        unless input[:response].processing?
          # puts 'vocabulary already processed'
          Representer::Song.new(OpenStruct.new) # rubocop:disable Style/OpenStructUse
            .from_json(input[:response].payload)
            .then { input[:vocabulary_song] = _1 }
        end
        Success(input)
      rescue StandardError
        Failure(MSG_REIFY_FAILED)
      end
    end
  end
end
