json.array!(@plays) do |play|
  json.extract! play, :id, :game_id, :player, :x, :y
end
