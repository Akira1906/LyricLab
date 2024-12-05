# frozen_string_literal: true

require_relative 'word'
require 'slim'

module Views
  # View for a a list of project entities
  class Vocabulary
    def initialize(vocabulary)
      @vocabulary = vocabulary
    end

    def sep_text
      @vocabulary.sep_text
    end

    def raw_text
      @vocabulary.raw_text
    end

    def unique_words
      @vocabulary.unique_words.map { |word| Views::Word.new(word) }
    end

    def origin_id
      @vocabulary.origin_id
    end

    def song
      @vocabulary.song
    end

    def rich_text
      Slim::Template.new('app/presentation/views_html/rich_text.slim')
        .render(self, vocabulary: self, song: @song)
    end

    def marked_text
      marked_text = raw_text
      unique_words.map(&:characters).sort_by(&:length).reverse.each do |word|
        marked_text.gsub!(word, "\\@#{word}\\$")
      end
      puts "text: #{marked_text}"
      marked_text
    end

    def entity
      @vocabulary
    end
  end
end
