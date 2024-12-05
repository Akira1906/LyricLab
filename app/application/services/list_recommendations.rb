# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Retrieves array of all recommended song entities (top searched)
    class ListRecommendations
      include Dry::Transaction

      step :get_recommendations
      step :reify_recommendations

      MSG_NO_RECOMMENDATIONS = 'Can\'t load recommendations.'
      MSG_FAILED_REIFY = 'Error in the ListRecommendations.'

      private

      def get_recommendations
        result = Gateway::Api.new(LyricLab::App.config)
          .list_recommendations

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace.join("\n")
        Failure(MSG_NO_RECOMMENDATIONS)
      end

      def reify_recommendations(recommendations_json)
        Representer::RecommendationsList.new(OpenStruct.new)
          .from_json(recommendations_json)
          .then { |songs| Success(songs) }
      rescue StandardError
        Failure(MSG_FAILED_REIFY)
      end
    end
  end
end
