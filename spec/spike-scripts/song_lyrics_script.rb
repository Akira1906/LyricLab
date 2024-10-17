# frozen_string_literal: true

require 'json'
require 'http'
require 'yaml'

BASE_URL = 'https://lrclib.net/api/get'

def call_api(_song_title, artist_name)
  url = BASE_URL.to_s
  params = {
    track_name:,
    artist_name:
  }

  HTTP.get(url, params: params)
end

def get_lyrics(received)
  result = received.parse
  return result['plainLyrics'] if result && result['plainLyrics']

  'Sorry... no lyrics found(('
end

song_title = '好不容易'
artist_name = '告五人'

response = call_api(song_title, artist_name)
if response.code == 200
  File.write('spec/fixtures/lyrics-success-results.yml', get_lyrics(response).to_yaml)
else
  File.write('spec/fixtures/lyrics-failure-results.yml', get_lyrics(response).to_yaml)
end
