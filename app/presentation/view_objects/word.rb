# frozen_string_literal: true

module Views
  class Word
    def initialize(word)
      @word = word
    end

    def characters
      @word.characters
    end

    def translation
      @word.translation
    end

    def pinyin
      @word.pinyin
    end

    def definition
      @word.definition
    end

    def example_sentence
      @word.example_sentence
    end

    def language_level
      "#{@word.language_level}-class"
    end
  end
end
