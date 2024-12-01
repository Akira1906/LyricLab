# frozen_string_literal: true

module Views
  # View for a a list of project entities
  class Song
    def initialize(song)
      @song = song
    end

    def vocabulary
      Views::Vocabulary.new(@song.vocabulary)
    end

    def title
      @song.title
    end

    def result_link
      "/search/result/#{origin_id}"
    end

    def origin_id
      @song.origin_id
    end

    def artist
      artist_name_string.split(',').first
    end

    def popularity
      @song.popularity
    end

    def artist_name_string
      @song.artist_name_string
    end

    def lyrics
      Views::Lyrics.new(@song.lyrics)
    end

    def preview_url
      @song.preview_url
    end

    def album_name
      @song.album_name
    end

    def cover_image_url_big
      @song.cover_image_url_big
    end

    def cover_image_url_medium
      @song.cover_image_url_medium
    end

    def cover_image_url_small
      @song.cover_image_url_small
    end

    def is_instrumental # rubocop:disable Naming/PredicateName
      @song.is_instrumental
    end

    def explicit
      @song.explicit
    end
  end
end
