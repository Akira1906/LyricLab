# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'lyrics_representer'
require_relative 'vocabulary_representer'

module LyricLab
  module Representer
    # Represents essential Song information for API output
    # USAGE:
    #   Song = Database::SongOrm.find(1)
    #   Representer::Song.new(song).to_json
    class Song < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia
      include Roar::Decorator::HypermediaConsumer

      property :title
      property :spotify_id
      property :popularity
      property :preview_url
      property :album_name
      property :artist_name_string
      property :cover_image_url_big
      property :cover_image_url_medium
      property :cover_image_url_small
      property :is_instrumental
      property :explicit

      property :vocabulary, extend: Representer::Vocabulary, class: OpenStruct
      property :lyrics, extend: Representer::Lyrics, class: OpenStruct

      link :self do
        "#{App.config.API_HOST}/api/v1/songs/#{sp_id}"
      end

      link :get_vocabulary do
        "#{App.config.API_HOST}/api/v1/vocabularies/#{sp_id}"
      end

      private

      def sp_id
        represented.spotify_id
      end
    end
  end
end
