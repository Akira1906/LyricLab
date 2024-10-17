# frozen_string_literal: true

module LyricLab
  module Lrclib
    # Data Mapper: LrcLib -> Lyrics entity
    class LyricsMapper
      def initialize(gateway_class = Lrclib::Api)
        @gateway_class = gateway_class
        @gateway = @gateway_class.new
      end

      def search(title, artist)
        data = @gateway.lyric_data(title, artist)
        build_entity(data)
      end

      def build_entity(data)
        DataMapper.new(data, @gateway_class).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data, gateway_class)
          @data = data
          @member_mapper = LyricsMapper.new(gateway_class)
        end

        def build_entity
          LyricLab::Entity::Lyrics.new(
            text: text ,
          )
        end

        def text
          @data['plainLyrics']
        end
      end
    end
  end
end
