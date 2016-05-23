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
      switch data.action
        when 'make_play'
          Turbolinks.clearCache()
          @updateGame data
        when 'request_play_again' then @requestPlayAgain data
        when 'confirm_play_again' then @confirmPlayAgain data
        when 'reject_play_again' then @rejectPlayAgain data
    
    updateGame: (data) ->
      if data.status == 0 # Game is still pending
        if data.userId != App.User.id
          if data.latestPlay
            App.Game.addPlay gameId, data.latestPlay
            $(".whose-turn[data-game-id='#{ gameId }']").text "Your turn"
            $(".last-game-activity[data-game-id='#{ gameId }']").text data.lastActivity
            $(".game[data-id='#{ gameId }']").addClass "playable"
          else
            Turbolinks.visit(window.location)
        $("#play_number").val(data.latestPlay.number + 1) if data.latestPlay
      else # Game is now over
        
        # Reload the page and also show the play-again button, which is hidden by default.
        $(document).one "turbolinks:load", ( -> $(".play-again").css display: "" )
        Turbolinks.visit(window.location)
    
    # Handle a request to play another game.
    requestPlayAgain: (data) ->
      # Only proceed if the user's opponent initiated the request to play again.
      return if data.user_id == App.User.id
      
      # Track the time to expiration of the invitation to play again, and if the timer
      # runs to zero, reload the page.
      expires = 1000 * data.expires # Convert Unix time from seconds to milliseconds.
      timerDelay = Math.max(expires - Date.now(), 0)
      playAgainTimeout = setTimeout ( -> Turbolinks.visit window.location ), timerDelay
      
      # Replace the play-again button with buttons to accept or reject the invitation
      # to play again.
      $(".play-again").parent().replaceWith '
        <section id="play-again-request">
          <p>Your opponent has invited you to play again!</p>
          <p>
            <button id="confirm-play-again" class="decide-play-again btn btn-primary">
              Play again
            </button>
            <button id="reject-play-again" class="decide-play-again btn btn-default">
              Decline
            </button>
          </p>
        </section>'
      
      # If the user navigates to a different page or chooses to accept or reject
      # the invitation to play another game, clear the play-again timeout. Also,
      # remove click handlers if the accept or reject button is clicked.
      $(document).one "turbolinks:load", ( -> clearTimeout playAgainTimeout )
      $(".decide-play-again").click ->
        clearTimeout playAgainTimeout
        $(".decide-play-again").off "click"
      
      # Handle user's acceptance of the invitation to play another game by sending
      # a confirmation message.
      $("#confirm-play-again").click =>
        @perform "confirm_play_again", user_id: App.User.id, expires: data.expires
      
      # Handle user's rejection of the invitation to play another game by sending
      # a rejection message.
      $("#reject-play-again").click =>
        @perform "reject_play_again", user_id: App.User.id
    
    # Handle notification of acceptance of the invitation to play another game by
    # navigating to the new game's address included with the notification.
    confirmPlayAgain: (data) ->
      Turbolinks.visit data.location
    
    # Handle notification of rejection of the invitation to play another game, indicating
    # this result to both users.
    rejectPlayAgain: (data) ->
      if data.user_id == App.User.id
        $("#play-again-request").text "You declined to play again."
      else
        $("#play-again-status").text "Your opponent declined to play again."

# Send a request to play another game if the user clicks the play-again button,
# which appears beneath games that have recently been completed. Also, indicate
# to the user that the opponent's response is being awaited.
$(document).on "click", ".play-again", (event) ->
  gameId = $(".game").data("id")
  $(this).replaceWith '<p id="play-again-status">Awaiting response from opponent...</p>'
  App.gameSubscriptions[gameId].perform "request_play_again", user_id: App.User.id