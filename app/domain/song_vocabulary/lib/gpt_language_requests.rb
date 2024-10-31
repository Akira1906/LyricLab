# frozen_string_literal: true

module LyricLab
  module Mixins
    # line credit calculation methods
    module GptLanguageRequests
      # hi carrie, you can start to implement the GPT library here
      #

      def self.extract_words(text)
        # should return a list of mandarin words
      end

      def self.generate_example_sentence(word, language_level)
        # should return a sentence with the word in it at the language level
      end

      def self.get_pinyin_translation(word)
        # should return the pinyin and translation of the word
        # in the format { pinyin: 'pinyin', translation: 'translation' }
      end
    end
  end
end
