require 'jwt'
require 'faraday'
require 'faraday_middleware'
require 'openssl'

module Spotify
  API_URI       = 'https://api.spotify.com/v1/'.freeze
  AUTHORIZE_URI = 'https://accounts.spotify.com/authorize'.freeze
  TOKEN_URI     = 'https://accounts.spotify.com/api/token'.freeze
  VERBS         = %w[get post put delete].freeze

  class << self
    def auth_header
      authorization = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
      { 'Authorization' => "Basic #{authorization}" }
    end

    def authenticate(client_id, client_secret)
      @client_id, @client_secret = client_id, client_secret
      request_body = { grant_type: 'client_credentials' }
      response = Faraday.post(TOKEN_URI, request_body, auth_header)
      @client_token = JSON.parse(response.body)['access_token']
      true
    end

    def client
      @client ||= Faraday.new(API_URI) do |conn|
        conn.headers['Authorization'] = "Bearer #{@client_token}"
        conn.adapter Faraday.default_adapter
      end
    end

    def method_missing(name, *args, &block)
      if client.respond_to?(name)
        client.send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      client.respond_to?(name, include_private)
    end
  end
end

Spotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'])
response = Spotify.get("playlists/2QWPQlcK6LcLVl6cIOM3ir")
tracks = JSON.parse(response.body)['tracks']['items']
tracks.each do |track|
  puts JSON.pretty_generate(track['track']['name'])
end
