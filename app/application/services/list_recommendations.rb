# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Retrieves array of all listed project entities
    class ListRecommendations
      include Dry::Transaction

      step :get_recommendations
      step :reify_recommendations

      def get_recommendations
        result = Gateway::Api.new(LyricLab::App.config)
          .list_recommendations

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        App.logger.error e.inspect
        App.logger.error e.backtrace
        Failure('Cannot find recommendations right now; please try again later')
      end

      def reify_recommendations(recommendations_json)
        # puts "ListRecommendations: #{recommendations_json}"
        Representer::RecommendationsList.new(OpenStruct.new)
          .from_json(recommendations_json)
          .then { |songs| Success(songs) }
      rescue StandardError
        Failure('Error in the Search Results -- please try again')
      end
    end
  end
end
