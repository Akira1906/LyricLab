# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'openstruct_with_links'
require_relative 'recommendation_representer'

module LyricLab
  module Representer
    # Represents list of recommendations
    class RecommendationsList < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia
      include Roar::Decorator::HypermediaConsumer

      collection :recommendations, extend: Representer::Recommendation, class: Representer::OpenStructWithLinks

      link :self do
        "#{App.config.API_HOST}/api/v1/recommendations"
      end
    end
  end
end
