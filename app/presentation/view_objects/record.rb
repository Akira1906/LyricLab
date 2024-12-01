# frozen_string_literal: true

module Views
  # View for a single recommendation entity
  class Record
    def initialize(recommendation)
      @recommendation = recommendation
    end

    def entity
      @recommendation
    end

    def result_link
      "/search/result/#{id}"
    end

    def title
      @recommendation.title
    end

    def artist
      @recommendation.artist_name_string
    end

    def id
      @recommendation.origin_id
    end
  end
end
