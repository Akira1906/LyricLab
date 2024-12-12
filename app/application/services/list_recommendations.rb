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
        # TODO: 1. Call the API to get the recommendations
      #   result = Gateway::Api.new(LyricLab::App.config)
      #     .list_recommendations

      #   result.success? ? Success(result.payload) : Failure(result.message)
      # rescue StandardError => e
      #   App.logger.error e.inspect
      #   App.logger.error e.backtrace.join("\n")
      #   Failure('Cannot find recommendations right now; please try again later')
        recommendations = Repository::Recommendations.top_searched_songs
        Success(recommendations)
        Failure("Cannot find recommendations right now; please try again later")
      end

      def reify_recommendations(recommendations_json)
        # puts "ListRecommendations: #{recommendations_json}"
        recommendations = Representer::RecommendationsList.new(OpenStruct.new)
          .from_json(recommendations_json)
        #   .then { |songs| Success(songs) }
          Success(Response::ApiResult.new(
            status: :ok,
            message: recommendations
          ))
      rescue StandardError
        App.logger.error "Failed to process recommendations: #{e.message}"
        Failure(Response::ApiResult.new(
          status: :internal_error,
          message: 'Error processing recommendations -- please try again'
        ))
      end
    end
  end
end
