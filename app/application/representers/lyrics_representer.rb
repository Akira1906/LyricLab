# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module LyricLab
  module Representer
    # Represents essential Lyrics information for API output
    # USAGE:
    #   lyrics = Database::LyricsOrm.find(1)
    #   Representer::Lyrics.new(lyrics).to_json
    class Lyrics < Roar::Decorator
      include Roar::JSON

      property :text
      property :is_mandarin
      property :is_explicit

      def mandarin?
        represented.is_mandarin
      end

      def explicit?
        represented.is_explicit
      end
    end
  end
end
