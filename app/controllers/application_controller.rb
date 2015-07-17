class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  def initialize()
  	api_key = "e148cf275908ee179642db16ab7ca7e3"
  	api_secret = "d5d7dbb421eed3ae35423269452f2a0f"
  	@lastfm = Lastfm.new(api_key, api_secret)
  end
  def tags_of_track(artist, track)
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
  	artist = params[:artist]
  	artist.gsub('+', ' ')
  	track = params[:track]
  	track.gsub('+', ' ')
  	
  	tags = tags_of_track(artist, track)
  	tracks_limit = 3
  	strings = []  
  	track_info = {}
  	
  	lsi = Classifier::LSI.new

  	tags.each do |tag|
  		tracks = @lastfm.tag.get_top_tracks(tag: tag, limit: tracks_limit)
  		tracks.each do |track|
  			t = tags_of_track(track["artist"]["name"], track["name"]).join(", ")
  			t = t + ":" + track["name"]
  			track_info[track["name"]] = {
  				"artist" => track["artist"]["name"],
  				"url" => track["url"],
  				"name" => track["name"],
  				#"image" => track["image"][0]["content"]
  			}
  			#track_info["image"] = track["image"][0]["content"]

  			if defined? track["image"][0]["content"]
  				track_info[track["name"]]["image"] = track["image"][0]["content"]
  			else
  				track_info[track["name"]]["image"] = "http://placehold.it/350x150"
  			end
  			strings.push(t)
  			#lsi.add_item(t, :ex)
  		end
  	end
  	strings = strings.uniq
	strings.each do |item|
		lsi.add_item(item, :ex)
	end
	ans = lsi.find_related(tags.join(", "), 3)
	ret = []
	

	ans.each do |item|
		track_tags, track_name = item.split(":")
		ret.push(track_info[track_name])
	end
	render json: ret
  end
  def index
  end
end
