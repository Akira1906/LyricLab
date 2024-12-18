# frozen_string_literal: true

module Views
  class Lyrics
    def initialize(lyrics)
      @lyrics = lyrics
    end

    def text
      @lyrics.text
    end

    def is_mandarin # rubocop:disable Naming/PredicateName
      @lyrics.is_mandarin
    end

    def is_instrumental # rubocop:disable Naming/PredicateName
      @lyrics.is_instrumental
    end
  end
end
