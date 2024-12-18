# frozen_string_literal: true

require_relative 'word'
require 'slim'

module Views
  # View for a a list of project entities
  class Vocabulary
    # DIFFICULTY_LEVELS = {
    #  1 => 'Beginner',
    #  2 => 'Intermediate',
    #  3 => 'Advanced',
    #  4 => 'Expert',
    #  5 => 'Master'
    # }.freeze

    LANG_TO_VOCAB_LEVELS = {
      'beginner'     => %w[beginner novice1 novice2],
      'intermediate' => %w[novice2 level1 level2],
      'advanced'     => %w[level2 level3 level4],
      'expert'       => %w[level3 level4 level5],
      'master'       => %w[level4 level5]
    }.freeze

    attr_reader :current_lang_level

    def initialize(vocabulary, current_lang_level = nil)
      @vocabulary = vocabulary
      @current_lang_level = current_lang_level
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
      marked_text
    end

    # def entity
    #  @vocabulary
    # end

    def language_difficulty
      return 0 if @vocabulary.language_difficulty.nil?

      case @vocabulary.language_difficulty
      when 0..1.5 then 1    # Beginner
      when 1.5..2.5 then 2  # Intermediate
      when 2.5..3.5 then 3  # Advanced
      when 3.5..4.5 then 4  # Expert
      else 5                # Master
      end
    end

    # def default_checked_levels
    #  DEFAULT_CHECKED_LEVELS[language_difficulty] || []
    # end

    def level_checked?(level)
      levels = LANG_TO_VOCAB_LEVELS[@current_lang_level]
      levels&.include?(level.to_s)
    end
  end
end
