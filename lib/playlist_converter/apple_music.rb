require 'jwt'
require 'faraday'
require 'faraday_middleware'
require 'openssl'

module AppleMusic
  API_URI = 'https://api.music.apple.com/v1/'
  class Config
    attr_accessor :auth_token

    def initialize
      @auth_token = get_auth_token
    end

    def get_auth_token
      token_expiration_time = 60 * 60 * 24
      algorithm = 'ES256'
      private_key = OpenSSL::PKey::EC.new(ENV['APPLE_MUSIC_SECRET_KEY'])
      team_id = ENV['APPLE_MUSIC_TEAM_ID']
      key_id = ENV['APPLE_MUSIC_KEY_ID']

      payload = {
        iss: team_id,
        iat: Time.now.to_i,
        exp: Time.now.to_i + token_expiration_time
      }

      JWT.encode(payload, private_key, algorithm, kid: key_id)
    end
  end

  class << self
    def initialize
      @auth_token = get_auth_token
    end

    def config
      @config ||= Config.new
    end

    def client
      @client ||= Faraday.new(API_URI) do |conn|
        conn.headers['Authorization'] = "Bearer #{config.auth_token}"
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

response = AppleMusic.get("catalog/us/playlists/pl.ea8a00ee10e94d7a9002583a337cbd3f")
tracks = JSON.parse(response.body)['data'][0]['relationships']['tracks']['data']
tracks.each do |track|
  puts JSON.pretty_generate track['attributes']['name']
end
