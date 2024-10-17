# frozen_string_literal: false

module LyricLab
  module Spotify
    # we don't need to talk to the api here yet
    class ArtistMapper
      def self.build_entity(data)
        DataMapper.new(data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data)
          @data = data
        end

        def build_entity
          LyricLab::Entity::Artist.new(
            name:  name ,
          )
        end

        def name
          @data['name']
        end
      end
    end
  end
end
