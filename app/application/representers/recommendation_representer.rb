# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module LyricLab
  module Representer
    # Represents essential Recommendation information for API output
    # USAGE:
    #   recommendation = Entity::Recommendation.new(...)
    #   Representer::Recommendation.new(recommendation).to_json
    class Recommendation < Roar::Decorator
      include Roar::JSON
      # include Roar::Hypermedia
      # include Roar::Decorator::HypermediaConsumer

      property :title
      property :artist_name_string
      property :search_cnt
      property :origin_id
    end
  end
end
