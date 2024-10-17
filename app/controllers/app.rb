# frozen_string_literal: true

require 'roda'
require 'slim'
require_relative '../models/entities/song'
require_relative '../models/entities/lyrics'
require_relative '../models/entities/album'
require_relative '../models/entities/artist'
require_relative '../models/gateways/lrclib_api'
require_relative '../models/gateways/spotify_api'

module LyricLab
  # Web App
  class App < Roda
    plugin :render, engine: 'slim', views: 'app/views'
    plugin :assets, css: 'style.css', path: 'app/views/assets'
    plugin :common_logger, $stderr
    plugin :halt
    plugin :flash

    route do |r|
      r.assets

      # GET /
      r.root do
        view 'home'
      end

      # GET /search
      r.on 'search' do
        r.is do
          # POST /search/
          r.post do
            search_string = r.params['search_query']
            r.redirect "/search/#{search_string}" if search_string
            r.redirect '/'
          end
        end

        # GET /search/:query
        r.on String do |query|
          r.get do
            song = Spotify::SongMapper
                   .new(SP_CLIENT_ID, SP_CLIENT_SECRET)
                   .find(query)
            lyrics = Lrclib::LyricsMapper
                     .new
                     .search(song.title, song.artists.first.name)
            view 'song', locals: { song:song , lyrics:lyrics }
          end
        end
      end
    end
  end
end
