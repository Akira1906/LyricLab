# frozen_string_literal: true

require_relative '../../../helpers/spec_helper'
# TEST_DATA = YAML.safe_load_file(File.join(File.dirname(__FILE__), 'fixtures', 'word_processor.yml'))
TEST_DATA = YAML.safe_load_file('spec/fixtures/word_processor.yml')
TEST_DATA['language_levels'].map!(&:to_sym)

WordProcessor = LyricLab::Mixins::WordProcessor
describe 'Test Word Processor library' do
  before do
    @words_to_filter = TEST_DATA['words_to_filter']
  end

  it "HAPPY: should filter the relevant words for language levels: #{TEST_DATA['language_levels']}" do
    filtered_words_list = [TEST_DATA['words_to_filter']]
    (TEST_DATA['language_levels']).each do |cur_language_level|
      filtered_words_list.append(WordProcessor.filter_relevant_words(@words_to_filter, cur_language_level))
      _(filtered_words_list[-1]).wont_equal TEST_DATA['words_to_filter']
      _(filtered_words_list[-1]).wont_equal filtered_words_list[-2]
      _(filtered_words_list[-1]).wont_be_nil
    end
  end
  it 'HAPPY: should filter nothing for the beginner level' do
    language_level = :beginner
    filtered_words = WordProcessor.filter_relevant_words(@words_to_filter, language_level)
    _(filtered_words).must_equal @words_to_filter
    _(filtered_words).wont_be_nil
  end
  it 'SAD: should raise exception when invalid language level is used' do
    invalid_language_level = :basic
    _(-> { WordProcessor.filter_relevant_words(@words_to_filter, invalid_language_level) }).must_raise ArgumentError
  end

  it 'HAPPY: should convert spimplified chinese text to traditional characters' do
    simplified_text = TEST_DATA['simplified_text']
    traditional_text = WordProcessor.convert_to_traditional(simplified_text)
    _(traditional_text).must_equal TEST_DATA['traditional_text']
    _(traditional_text).wont_be_nil
  end

  it 'HAPPY: should not change english text' do
    english_text = TEST_DATA['english_text']
    traditional_text = WordProcessor.convert_to_traditional(english_text)
    _(traditional_text).must_equal TEST_DATA['english_text']
    _(traditional_text).wont_be_nil
  end
end
