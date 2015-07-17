class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  def initialize()
  	# Creates Lastfm object
  	api_key = ""
  	api_secret = ""
  	@lastfm = Lastfm.new(api_key, api_secret)
  end
  def tags_of_track(artist, track)
  	# Returns the array of tags of the song
  	res = []
  	tags = @lastfm.track.get_top_tags(artist: artist, track: track, autocorrect: 1)
  	limit = 3
  	i = 0
  	tags.each do |tag|
  		if i < limit
  			res.push(tag["name"])
  			i = i + 1
  		else
  			break
  		end
  	end
  	#puts res
  	return res
  end
  def load
  	# Loads 3 recommended songs
  	# Returns their data in JSON format
	
	# Retrieve data.
  	artist = params[:artist]
  	artist.gsub('+', ' ')
  	track = params[:track]
  	track.gsub('+', ' ')

	# Get tags of current song  	
  	tags = tags_of_track(artist, track)
  	
  	# Basic variables
  	tracks_limit = 3

  	# Array of the strings in this format:
  	# "% tags, devided by comma% : % name of the song%"
  	strings = [] 

  	track_info = {} # Information about song by it's name
  	
  	lsi = Classifier::LSI.new

  	tags.each do |tag|
  		# For each tag, get it's top songs
  		# For each song that we got, get tags of this song

  		tracks = @lastfm.tag.get_top_tracks(tag: tag, limit: tracks_limit)
  		tracks.each do |item|
  			t = tags_of_track(item["artist"]["name"], item["name"]).join(", ")
  			t = t + ":" + item["name"]
  			track_info[item["name"]] = {
  				"artist" => item["artist"]["name"],
  				"url" => item["url"],
  				"name" => item["name"]
  			}
  			# If current song is not base song
  			# add it's tags and name to "strings" list
  			if defined? item["image"][0]["content"]
  				track_info[item["name"]]["image"] = item["image"][0]["content"]
  			else
  				track_info[item["name"]]["image"] = "http://placehold.it/350x150"
  			end
  			if item["name"].downcase == track.downcase and item["artist"]["name"].downcase == artist.downcase
  				next
  			else
  				strings.push(t)
  			end
  		end
  	end
  	strings = strings.uniq # Make all elements unique, in order to prevent repeated songs
	strings.each do |item|
		lsi.add_item(item, :ex) # Add all songs to LSI
	end
	ans = lsi.find_related(tags.join(", "), 3) # Get related songs
	ret = [] # Array, which will be converted to JSON
	

	ans.each do |item|
		# For each resulting song, get their data
		track_tags, track_name = item.split(":")
		ret.push(track_info[track_name])
	end

	render json: ret
  end
  def index
  end
end
