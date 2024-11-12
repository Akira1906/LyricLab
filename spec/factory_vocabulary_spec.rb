# frozen_string_literal: false

require_relative 'helpers/spec_helper'
require_relative 'helpers/vcr_helper'
require_relative 'helpers/database_helper'

describe 'Integration test of word processing and GPT to test vocabulary functions' do
  VcrHelper.setup_vcr
  before do
    VcrHelper.configure_vcr_for_gpt
  end

  after do
    VcrHelper.eject_vcr
  end

  describe 'Retrieve song data, generate Vocabulary' do
    before do
      DatabaseHelper.wipe_database
    end

    it 'HAPPY: should be able to get song data from Spotify and add filtered_words to vocabulary' do
      song = LyricLab::Spotify::SongMapper
        .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, GOOGLE_CLIENT_KEY)
        .find(CORRECT_SONG['title'])
      song.vocabulary.gen_unique_words(song.lyrics.text, GPT_API_KEY)

      _(song.vocabulary.unique_words).wont_be_empty
    end

    it 'HAPPY: should be able to persist vocabulary to database' do
      song = LyricLab::Spotify::SongMapper
        .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, GOOGLE_CLIENT_KEY)
        .find(CORRECT_SONG['title'])

      song.vocabulary.gen_unique_words(song.lyrics.text, GPT_API_KEY)
      rebuilt = LyricLab::Repository::For.entity(song).create(song)

      _(rebuilt.vocabulary.unique_words).wont_be_empty
    end

    it 'HAPPY: should be able to retrieve song vocabulary from a song with vocabulary by spotify_id' do
      song = LyricLab::Spotify::SongMapper
        .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, GOOGLE_CLIENT_KEY)
        .find(CORRECT_SONG['title'])

      song.vocabulary.gen_unique_words(song.lyrics.text, GPT_API_KEY)

      LyricLab::Repository::For.entity(song).create(song)
      rebuilt = LyricLab::Repository::For.klass(LyricLab::Entity::Song).find_spotify_id(song.spotify_id)
      rebuilt.vocabulary.gen_unique_words(rebuilt.lyrics.text, GPT_API_KEY) if rebuilt.vocabulary.unique_words.empty?

      _(rebuilt.vocabulary.unique_words.length).must_equal(song.vocabulary.unique_words.length)
      _(rebuilt.vocabulary.unique_words.first.characters).must_equal(song.vocabulary.unique_words.first.characters)
    end

    it 'HAPPY: should be able to retrieve song vocabulary from a song WITHOUT vocabulary by spotify_id' do
      song = LyricLab::Spotify::SongMapper
        .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, GOOGLE_CLIENT_KEY)
        .find(CORRECT_SONG['title'])
      LyricLab::Repository::For.entity(song).create(song)

      rebuilt = LyricLab::Repository::For.klass(LyricLab::Entity::Song).find_spotify_id(song.spotify_id)
      rebuilt.vocabulary.gen_unique_words(rebuilt.lyrics.text, GPT_API_KEY) if rebuilt.vocabulary.unique_words.empty?

      _(rebuilt.vocabulary.unique_words.length).wont_equal(0)
      _(rebuilt.vocabulary.unique_words.first.characters).wont_be_empty
    end

    it 'HAPPY: should be able to retrieve empty vocabulary from db populate it and then persist' do
      song = LyricLab::Spotify::SongMapper
        .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, GOOGLE_CLIENT_KEY)
        .find(CORRECT_SONG['title'])
      LyricLab::Repository::For.entity(song).create(song)

      rebuilt = LyricLab::Repository::For.klass(LyricLab::Entity::Song).find_spotify_id(song.spotify_id)
      rebuilt.vocabulary.gen_unique_words(rebuilt.lyrics.text, GPT_API_KEY) if rebuilt.vocabulary.unique_words.empty?
      LyricLab::Repository::For.entity(rebuilt).update(rebuilt)

      rebuilt2 = LyricLab::Repository::For.klass(LyricLab::Entity::Song).find_spotify_id(song.spotify_id)

      _(rebuilt2.vocabulary.unique_words.length).wont_equal(0)
      _(rebuilt2.vocabulary.unique_words.length).must_equal(rebuilt.vocabulary.unique_words.length)
      _(rebuilt2.vocabulary.unique_words.first.characters).wont_be_empty
    end
  end
end
