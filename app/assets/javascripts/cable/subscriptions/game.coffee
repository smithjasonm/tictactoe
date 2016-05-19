window.App || (window.App = {})
App.gameSubscriptions = {}

$(document).on "turbolinks:load", ->
  $games = $(".game")
  App.unsubscribeFromOldGames($games)
  App.subscribeToNewGames($games)

# Unsubscribe from games no longer visible
App.unsubscribeFromOldGames = ($games) ->
  gameIds = for game in $games
    $(game).data("id")
  for own gameId, subscription of App.gameSubscriptions
    if +gameId not in gameIds
      console.log "unsubscribing from game #{ gameId }"
      subscription.unsubscribe()
      delete App.gameSubscriptions[gameId]

# Subscribe to visible games not yet subscribed to
App.subscribeToNewGames = ($games) ->
  for game in $games
    $game = $(game)
    gameId = $game.data("id")
    if gameId not of App.gameSubscriptions
      console.log "subscribing to game #{ gameId }"
      App.subscribe $game

# Subscribe to game
App.subscribe = ($game) ->
  gameId = $game.data("id")
  App.gameSubscriptions[gameId] = App.cable.subscriptions.create {
                                                          channel: "GameChannel"
                                                          id: gameId
                                                        },
    make_play: (data) ->
      @perform "make_play", data
    
    received: (data) ->
      @updateGame data
    
    updateGame: (data) ->
      if data.status == 0
        if data.user_id != App.User.id
          App.Game.addPlay gameId, data.latestPlay
          $(".whose_turn[data-game-id='#{ gameId }']").text "Your turn"
          $game.addClass "playable"
        $("#play_number").val(data.latestPlay.number + 1)
      else
        Turbolinks.visit(window.location)