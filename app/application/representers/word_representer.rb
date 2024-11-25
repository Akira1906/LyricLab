# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module LyricLab
  module Representer
    # Represents essential Word information for API output
    class Word < Roar::Decorator
      include Roar::JSON

      property :characters
      property :translation
      property :pinyin
      property :language_level
      property :definition
      property :word_type
      property :example_sentence
    end
  end
end
