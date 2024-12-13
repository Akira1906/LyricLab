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

    MAX_SESSION_SIZE = 4096 # to control for cookies size

    # Flash messages
    MSG_NO_RECOMMENDATIONS = 'No recommendations found'
    MSG_NO_SEARCH_RESULTS = 'No search results found'
    MSG_ERROR_SEARCH_RESULTS = 'Can\'t find these search results'
    MSG_NO_VOCABULARY = 'Can\'t find vocabulary for this song'
    MSG_ERROR_RECORD_RECOMMENDATIONS = 'Can\'t update recommendations based on this action'
    MSG_NO_RECOMMENDATIONS_AVAILABLE = 'No recommendations available yet'
    MSG_ERROR = 'Something went wrong'
    MSG_COOKIE = 'Couldn\'t load search history'

    route do |routing| # rubocop:disable Metrics/BlockLength
      routing.public
      routing.assets # load CSS
      response['Content-Type'] = 'text/html; charset=utf-8'

      # cookies
      session[:search_history] ||= []
      session[:lang_difficulty] ||= ''

      # GET /
      routing.root do
        first_time = session[:first_visit].nil?
        session[:first_visit] = false

        session[:lang_difficulty] = routing.params['language_level'] unless first_time
        puts session[:lang_difficulty] unless first_time

        # check cookies size
        session_size = session[:search_history].to_json.bytesize
        session[:search_history].pop(2) if session_size > MAX_SESSION_SIZE

        viewable_search_history = Service::LoadSongsById.new.call(session[:search_history])
        viewable_search_history = if viewable_search_history.failure?
                                    # flash[:error] = MSG_COOKIE no need to show error
                                    []
                                  else
                                    Views::SongsList.new(viewable_search_history.value!.songs)
                                  end

        # TODO: get recommendations for each language_level from the API
        viewable_recommendations = Service::ListRecommendations.new.call
        if viewable_recommendations.failure?
          flash.now[:error] = MSG_NO_RECOMMENDATIONS
          viewable_recommendations = []
        else
          viewable_recommendations = viewable_recommendations.value!.recommendations
          flash.now[:notice] = MSG_NO_RECOMMENDATIONS_AVAILABLE if viewable_recommendations.none?
          viewable_recommendations = Views::SongsList.new(viewable_recommendations)
        end

        # response.expires 60, public: true
        # puts "Recommendations: #{viewable_recommendations.inspect}, Search History: #{viewable_search_history.inspect}"
        view 'home',
             locals: { recommendations: viewable_recommendations, song_history: viewable_search_history, first_time: }
      rescue StandardError => e
        App.logger.error(e)
        flash[:error] = MSG_ERROR
        routing.redirect '/'
      end

      routing.on 'search' do # rubocop:disable Metrics/BlockLength
        routing.is do
          # POST /search/
          routing.post do
            response.expires 60, public: true
            search_string = Forms::NewSearch.new.call(routing.params)
            search_results = Service::FindSongsFromSearch.new.call(search_string)
            puts "search_results: #{search_results.inspect}"
            raise search_results.failure if search_results.failure?

            songs = search_results.value!.songs
            session[:search_result_ids] = songs.map(&:origin_id)

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

            result = Service::LoadSongsById.new.call(search_ids.split('-'))
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

            result = Service::LoadVocabulary.new.call(
              origin_id: origin_id
            )
            puts "result: #{result.inspect}"
            if result.failure?
              flash[:error] = result.failure
              raise result.failure
            end

            vocabulary_song = OpenStruct.new(result.value!)
            if vocabulary_song.response.processing?
              flash[:notice] = 'Vocabulary Information for the song is being generated, ' \
                               'please check back in a moment(~1 min).'
              routing.redirect request.referer || '/'
            end

            vocabulary_song = vocabulary_song.vocabulary_song
            unless session[:search_history].include?(vocabulary_song.origin_id)
              session[:search_history] << vocabulary_song.origin_id
            end

            viewable_song = Views::Song.new(vocabulary_song)

            # Only use browser caching in production
            App.configure :production do
              response.expires 60, public: true
            end

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
