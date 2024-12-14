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
    MSG_TARGETED_RECOMMENDATIONS_NOT_AVAILABLE = 'For some language difficulties, no recommendations are available'
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

        # current_level = session['language_level'] || 'beginner'

        session[:lang_difficulty] = routing.params['language_level'] unless first_time

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
        language_difficulties = [1,3,4,5,7]
        # this is gonna be a list of song metadata lists
        view_recommendations_by_difficulty = []
        language_difficulties.each do |language_difficulty|
          view_recommendations_by_difficulty.append(Service::ListTargetedRecommendations.new.call(language_difficulty))
          if view_recommendations_by_difficulty.last.failure?
            flash.now[:error] = MSG_NO_RECOMMENDATIONS
            view_recommendations_by_difficulty.last = []
          else
            view_recommendations_by_difficulty[-1] = view_recommendations_by_difficulty.last.value!.recommendations
            flash.now[:notice] = MSG_NO_RECOMMENDATIONS_AVAILABLE if view_recommendations_by_difficulty.last.none?
            view_recommendations_by_difficulty[-1] = Views::SongsList.new(view_recommendations_by_difficulty.last)
          end
        end

        current_level = session[:lang_difficulty] || 'beginner'
        
        
        view 'home',
             locals: { 
              recommendations_by_difficulty: view_recommendations_by_difficulty, 
              song_history: viewable_search_history, 
              first_time:first_time,
              current_level: current_level }

      rescue StandardError => e
        App.logger.error(e)
        flash[:error] = MSG_ERROR
        routing.redirect '/'
      end

      routing.on 'update_language_level' do
        routing.post do
          request_payload = JSON.parse(routing.body.read)
          session[:lang_difficulty] = request_payload['language_level']
          
          response.status = 200
          { status: 'success',
           language_level: session[:lang_difficulty],
          redirect_url:'/' }.to_json
        end
      end

      routing.on 'search' do # rubocop:disable Metrics/BlockLength
        routing.is do
          # POST /search/
          routing.post do
            response.expires 60, public: true
            search_string = Forms::NewSearch.new.call(routing.params)
            search_results = Service::FindSongsFromSearch.new.call(search_string)
            
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
            search_ids = Base64.urlsafe_decode64(routing.params['i'])

            result = Service::LoadSongsById.new.call(search_ids.split('-'))
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

            current_lang_level = session[:lang_difficulty]
            viewable_vocabulary = Views::Vocabulary.new(vocabulary_song, current_lang_level)
            viewable_song = Views::Song.new(vocabulary_song)

            # Only use browser caching in production
            App.configure :production do
              response.expires 60, public: true
            end

            # Show viewer the song
            view 'song', locals: { 
              vocabulary: viewable_vocabulary,  
              song: viewable_song,          
              current_lang_level: current_lang_level || 'beginner' }
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
