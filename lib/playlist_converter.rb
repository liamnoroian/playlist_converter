require_relative "playlist_converter/version"
require_relative "playlist_converter/apple_music"

module PlaylistConverter
  class Error < StandardError; end
  AppleMusicApi.authorize
  songs = AppleMusicApi.search_song("hi")
  songs.each { |song| puts song.name, song.artist_name }
end
