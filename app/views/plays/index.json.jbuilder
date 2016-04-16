json.array!(@plays) do |play|
  json.extract! play, :id, :game_id, :player, :x, :y
  json.url play_url(play, format: :json)
end
