# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'
require_relative 'song_representer'

module LyricLab
  module Representer
    # Represents a list of song history
    class SearchResults < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia
      include Roar::Decorator::HypermediaConsumer

      collection :songs, extend: Representer::Song, class: OpenStructWithLinks

      link :self do
        "#{App.config.API_HOST}/api/v1/search_results"
      end
    end
  end
end
