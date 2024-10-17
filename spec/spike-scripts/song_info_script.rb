# frozen_string_literal: true

require 'http'
require 'yaml'
require 'json'

def renew_token(config)
  url = 'https://accounts.spotify.com/api/token'
  headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
  body = {
    grant_type: 'client_credentials',
    client_id: config['SPOTIFY_CLIENT_ID'],
    client_secret: config['SPOTIFY_CLIENT_SECRET']
  }
  HTTP.headers(headers).post(url, form: body).parse['access_token']
end

def token_is_alive?(config)
  url = 'https://api.spotify.com/v1/artists/2fBURuq7FrlH6z5F92mpOl'

  # Set up the headers, including the authorization token
  headers = {
    'Authorization' => "Bearer #{config['SPOTIFY_BEARER_TOKEN']}"
  }

  response = HTTP.headers(headers).get(url)
  response.code != 401
end

def get_song_id(song_name, config)
  url = "https://api.spotify.com/v1/search?q=#{song_name}&type=track&market=TW&limit=1"
  headers = { 'Authorization' => "Bearer #{config['SPOTIFY_BEARER_TOKEN']}" }
  response = HTTP.headers(headers).get(url)
  response.parse['tracks']['items'][0]['id']
end

def get_song_info(song_id, config)
  url = "https://api.spotify.com/v1/tracks/#{song_id}"
  headers = { 'Authorization' => "Bearer #{config['SPOTIFY_BEARER_TOKEN']}" }
  response = HTTP.headers(headers).get(url)
  response.parse
end

# Load the configuration
config = YAML.safe_load_file('secrets.yml')

# Renew the token if it's not alive
unless token_is_alive?(config)
  puts 'Renewing the token...'
  config['SPOTIFY_BEARER_TOKEN'] = renew_token(config)
  File.write('secrets.yml', config.to_yaml)
end

spotify_results = {}

# Spotify Search query to get the song id
song_id = get_song_id('山海', config)
puts "Found song id: #{song_id}"

# Spotify API query to get the song information
song_info = get_song_info(song_id, config)
puts "Found song info: #{song_info}"

spotify_results['song_name'] = song_info['name']
spotify_results['artist_name'] = song_info['artists'][0]['name']
spotify_results['album'] = song_info['album']['name']
spotify_results['release_date'] = song_info['album']['release_date']
spotify_results['duration'] = song_info['duration_ms']

# add to return popularity,preview_url
spotify_results['popularity'] = song_info['popularity']
spotify_results['preview_url'] = song_info['preview_url']

## BAD request to Spotify API

url = 'https://api.spotify.com/v1/shmekels/many'
headers = { 'Authorization' => "Bearer #{config['SPOTIFY_BEARER_TOKEN']}" }
bad_spotify_response = HTTP.headers(headers).get(url)
puts "bad request: #{bad_spotify_response.parse}"

# Write the song info to a YAML file
puts 'Writing song info to file...'
File.write('../spec/fixtures/spotify_results.yml', spotify_results.to_yaml)
