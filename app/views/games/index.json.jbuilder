json.array!(@games) do |game|
  json.extract! game, :id, :player1, :player2, :status
  json.url game_url(game, format: :json)
end
