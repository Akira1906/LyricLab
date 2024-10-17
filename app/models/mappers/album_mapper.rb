# frozen_string_literal: false

module LyricLab
  module Spotify
    # we don't need to talk to the api here yet
    class AlbumMapper
      # Extracts entity specific elements from data structure
      def self.build_entity(data)
        DataMapper.new(data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data)
          @data = data
        end

        def build_entity
          LyricLab::Entity::Album.new(
            name:,
            cover_image_url_big:,
            cover_image_url_medium:,
            cover_image_url_small:
          )
        end

        def name
          @data['name']
        end

        def cover_image_url_big
          @data['images'][0]['url']
        end

        def cover_image_url_medium
          @data['images'][1]['url']
        end

        def cover_image_url_small
          @data['images'][2]['url']
        end
      end
    end
  end
end
