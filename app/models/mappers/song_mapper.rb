# frozen_string_literal: false

require_relative 'album_mapper'

module LyricLab
  module Spotify
    # Data Mapper: Spotify Track -> Song Entity
    class SongMapper
      def initialize(sp_client_id, sp_client_secret, gateway_class = Spotify::Api)
        @client_id = sp_client_id
        @client_secret = sp_client_secret
        @gateway = gateway_class.new(@client_id, @client_secret)
      end

      def find(search_string)
        data = @gateway.track_data(search_string)
        build_entity(data)
      end

      def build_entity(data)
        DataMapper.new(data, @client_id, @client_secret, @gateway_class).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data, _client_id, _client_secret, _gateway_class)
          @data = data['tracks']['items'][0] # right now we can only parse a single song
        end

        def build_entity
          LyricLab::Entity::Song.new(
            title: title ,
            artists: artists ,
            popularity: popularity ,
            album: album ,
            preview_url: preview_url
          )
        end

        def title
          @data['name']
        end

        def artists
          @data['artists'].map do |artist_data|
            ArtistMapper.build_entity(artist_data)
          end
        end

        def popularity
          @data['popularity']
        end

        def album
          AlbumMapper.build_entity(@data['album'])
        end

        def preview_url
          @data['preview_url']
        end
      end
    end
  end
end
