window.App || (window.App = {})
App.gameSubscriptions = {}

$(document).on "turbolinks:load", ->
  
  # Collect IDs of pending games on current page.
  gameIds = for game in $(".game[data-status='0']")
    $(game).data("id")
  
  # Unsubscribe from updates for games absent from page.
#  App.unsubscribeFromOldGames(gameIds)
  
  # Subscribe to updates for pending games present on page.
  App.subscribeToNewGames(gameIds)

# Unsubscribe from updates for games with given IDs.
# App.unsubscribeFromOldGames = (gameIds) ->
#   for own gameId, subscription of App.gameSubscriptions
#     if +gameId not in gameIds
#       subscription.unsubscribe()
#       delete App.gameSubscriptions[gameId]

# Subscribe to updates for games with given IDs whose updates are not yet subscribed to.
App.subscribeToNewGames = (gameIds) ->
  App.subscribeToGame id for id in gameIds when id not of App.gameSubscriptions

# Subscribe to updates for game with given id.
App.subscribeToGame = (gameId) ->
  App.gameSubscriptions[gameId] = App.cable.subscriptions.create {
                                                          channel: "GameChannel"
                                                          id: gameId
                                                        },
    make_play: (data) ->
      @perform "make_play", data
    
    received: (data) ->
      Turbolinks.clearCache()
      @updateGame data
    
    updateGame: (data) ->
      if data.status == 0
        if data.userId != App.User.id
          if data.latestPlay
            App.Game.addPlay gameId, data.latestPlay
            $(".whose-turn[data-game-id='#{ gameId }']").text "Your turn"
            $(".last-game-activity[data-game-id='#{ gameId }']").text data.lastActivity
            $(".game[data-id='#{ gameId }']").addClass "playable"
          else
            Turbolinks.visit(window.location)
        $("#play_number").val(data.latestPlay.number + 1) if data.latestPlay
      else
        Turbolinks.visit(window.location)