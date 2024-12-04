# frozen_string_literal: true

require 'rack' # for Rack::MethodOverride
require 'roda'
require 'slim'
require 'slim/include'

module LyricLab
  # Web App
  class App < Roda
    plugin :caching
    plugin :sessions, secret: config.SESSION_SECRET
    plugin :flash
    plugin :all_verbs # allows HTTP verbs beyond GET/POST (e.g., DELETE)
    plugin :render, engine: 'slim', views: 'app/presentation/views_html'
    plugin :public, root: 'app/presentation/public'
    plugin :assets, path: 'app/presentation/assets',
                    css: 'style.css', js: 'table_row.js'
    plugin :common_logger, $stderr
    plugin :halt

    use Rack::MethodOverride # allows HTTP verbs beyond GET/POST (e.g., DELETE)

    # Flash messages
    MSG_NO_RECOMMENDATIONS = 'No recommendations found'
    MSG_NO_SEARCH_RESULTS = 'No search results found'
    MSG_ERROR_SEARCH_RESULTS = 'Can\'t find these search results'
    MSG_NO_VOCABULARY = 'Can\'t find vocabulary for this song'
    MSG_ERROR_RECORD_RECOMMENDATIONS = 'Can\'t update recommendations based on this action'
    MSG_NO_RECOMMENDATIONS_AVAILABLE = 'No recommendations available yet'
    MSG_ERROR = 'Something went wrong'

    route do |routing| # rubocop:disable Metrics/BlockLength
      routing.assets # load CSS
      response['Content-Type'] = 'text/html; charset=utf-8'
      routing.public
      session[:song_history] ||= []

      # GET /
      routing.root do
        session[:search_result_ids] = []

        viewable_song_history = Service::LoadSongHistory.new.call(session[:song_history])
        viewable_song_history = if viewable_song_history.failure?
                                  flash[:error]
                                  []
                                else
                                  viewable_song_history.value!
                                end

        result = Service::ListRecommendations.new.call
        viewable_recommendations = []
        if result.failure?
          flash.now[:error] = MSG_NO_RECOMMENDATIONS
        else
          recommendations = result.value!.recommendations
          flash.now[:notice] = MSG_NO_RECOMMENDATIONS_AVAILABLE if recommendations.none?
          viewable_recommendations = Views::SongsList.new(recommendations)
        end

        # response.expires 60, public: true
        puts "Recommendations: #{viewable_recommendations.inspect}, Song History: #{viewable_song_history.inspect}"
        view 'home', locals: { recommendations: viewable_recommendations, song_history: viewable_song_history }
      rescue StandardError => e
        App.logger.error(e)
        flash[:error] = MSG_ERROR
        routing.redirect '/'
      end

      routing.on 'search' do # rubocop:disable Metrics/BlockLength
        routing.is do
          # POST /search/
          routing.post do
            search_string = Forms::NewSearch.new.call(routing.params)
            search_results = Service::FindSongsFromSearch.new.call(search_string)
            puts "search_results: #{search_results.inspect}"
            raise search_results.failure if search_results.failure?

            songs = search_results.value!.songs
            session[:search_result_ids] = songs.map(&:origin_id)
            puts "search/results/?i=#{Gateway::Value::Query.to_encoded(songs.map(&:origin_id).join('-'))}"
            routing.redirect "search/results/?i=#{Base64.urlsafe_encode64(songs.map(&:origin_id).join('-'))}"
          rescue StandardError => e
            App.logger.error(e)
            flash[:error] = MSG_NO_SEARCH_RESULTS
            routing.redirect '/'
          end
        end

        routing.on 'results' do
          # GET /search/results/?i={search_ids}
          routing.get do
            # puts "before: search_ids: #{routing.params['i']}"
            search_ids = Base64.urlsafe_decode64(routing.params['i'])
            # puts "search_ids: #{search_ids}"

            result = Service::LoadSearchResults.new.call(search_ids.split('-'))
            # puts "results: #{result.inspect}"
            raise result.failure.to_s if result.failure?

            search_results = result.value!.songs
            viewable_search_results = Views::SongsList.new(search_results)

            view 'suggestion', locals: { suggestions: viewable_search_results }
          rescue StandardError => e
            App.logger.error(e)
            flash[:error] = MSG_ERROR_SEARCH_RESULTS
            routing.redirect '/'
          end
        end

        # GET /result/{spotify_id}
        routing.on 'result', String do |origin_id|
          routing.get do
            record_result = Service::RecordRecommendation.new.call(origin_id)
            # The system should still work if the recording fails
            flash.now[:error] = MSG_ERROR_RECORD_RECOMMENDATIONS if record_result.failure?

            vocabulary_song = Service::LoadVocabulary.new.call(origin_id)
            raise vocabulary_song.failure if vocabulary_song.failure?

            vocabulary_song = vocabulary_song.value!

            viewable_song = Views::Song.new(vocabulary_song)

            # Show viewer the song
            view 'song', locals: { song: viewable_song }
          rescue StandardError => e
            App.logger.error(e)
            flash[:error] = MSG_NO_VOCABULARY
            routing.redirect '/'
          end
        end
      end
    end
  end
end
