# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'word_representer'

module LyricLab
  module Representer
    # Represents essential Vocabulary information for API output
    # USAGE:
    #   Vocabulary = Database::VocabularyOrm.find(1)
    #   Representer::Vocabulary.new(vocabulary).to_json
    class Vocabulary < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia
      include Roar::Decorator::HypermediaConsumer

      property :unique_words
      property :sep_text
      # collection :unique_words, extend: Representer::Word, class: OpenStruct
      # property :unique_words, extend: Representer::Word, class: OpenStruct
    end
  end
end
