# frozen_string_literal: true

require 'dry/transaction'

module LyricLab
  module Service
    # Retrieves array of all listed project entities
    class Record
      include Dry::Transaction

      step :record_request

      def record_request(origin_id)
        result = Gateway::Api.new(LyricLab::App.config)
          .record_recommendation(origin_id)

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError => e
        puts e.inspect
        puts e.backtrace
        Failure('Cannot record recommendation right now; please try again later')
      end
    end
  end
end
