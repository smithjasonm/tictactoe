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
    # Handle receipt of messages from server.
    received: (data) ->
      switch data.action
        when 'make_play' then @makePlay data
        when 'update_game' then Turbolinks.visit window.location
        when 'request_play_again' then @requestPlayAgain data
        when 'confirm_play_again' then @confirmPlayAgain data
        when 'reject_play_again' then @rejectPlayAgain data
        when 'cannot_play_again' then @cannotPlayAgain data
        when 'cancel_play_again' then @cancelPlayAgain data
    
    # Respond to a message that a play has been made.
    makePlay: (data) ->
      Turbolinks.clearCache()
      if data.status == 0 # Game is still pending
        if data.userId == App.User.id
          $game = $(".game[data-id='#{ gameId }']")
          opponent_handle = $game.data("opponent-handle")
          $(".whose-turn[data-game-id='#{ gameId }']").text "#{ opponent_handle }'s turn"
        else
          App.Game.addPlay gameId, data.latestPlay
          $(".whose-turn[data-game-id='#{ gameId }']").text "Your turn"
          $(".last-game-activity[data-game-id='#{ gameId }']").text data.lastActivity
          $(".game[data-id='#{ gameId }']").addClass "playable"
        $("#play_number").val(data.latestPlay.number + 1) if data.latestPlay
      else # Game is now over
        
        # Reload the page and also show the play-again button, which is hidden by default.
        $(document).one "turbolinks:load", ( -> $(".play-again").css display: "" )
        Turbolinks.visit(window.location)
    
    # Handle a request to play another game.
    requestPlayAgain: (data) ->
      # Only proceed if the user's opponent initiated the request to play again.
      return if data.user_id == App.User.id
      
      # If user is no longer on game page, send message of unavailability and return.
      if $(".game[data-id='#{ gameId }']").length == 0
        @perform "cannot_play_again"
        return
      
      # Track the time to expiration of the invitation to play again, and if the timer
      # runs to zero, reload the page, which will also result in the sending
      # of a message of unavailability by a page-load handler to be attached below.
      expires = 1000 * data.expires # Convert Unix time from seconds to milliseconds.
      timerDelay = Math.max(expires - Date.now(), 0)
      @playAgainTimeout = setTimeout ( -> Turbolinks.visit window.location ), timerDelay
      
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
      
      # If the user navigates to a different page while an invitation to play again is
      # pending, clear the timeout and send a message of unavailability.
      $(document).one "turbolinks:visit.playAgain", =>
        clearTimeout @playAgainTimeout
        @perform "cannot_play_again"
      
      # When the user clicks to accept or reject the invitation to play another game,
      # clear the timeout and remove the relevant click and page-load handlers.
      $(".decide-play-again").click =>
        clearTimeout @playAgainTimeout
        $(".decide-play-again").off "click"
        $(document).off "turbolinks:visit.playAgain"
      
      # Handle user's acceptance of the invitation to play another game by sending
      # a confirmation message.
      $("#confirm-play-again").click =>
        @perform "confirm_play_again", expires: data.expires
      
      # Handle user's rejection of the invitation to play another game by sending
      # a rejection message.
      $("#reject-play-again").click =>
        @perform "reject_play_again"
    
    # Handle notification of acceptance of the invitation to play another game by
    # navigating to the new game's address included with the notification. Also,
    # remove turbolinks:visit handler to avoid canceling play-again request,
    # and clear Turbolinks cache.
    confirmPlayAgain: (data) ->
      $(document).off "turbolinks:visit.playAgain" unless data.user_id == App.User.id
      $(document).one "turbolinks:load.playAgain", -> Turbolinks.clearCache()
      Turbolinks.visit data.location
    
    # Handle notification of rejection of the invitation to play another game, indicating
    # this result to both users.
    rejectPlayAgain: (data) ->
      if data.user_id == App.User.id
        $("#play-again-request").text "You declined to play again."
      else
        $(document).off "turbolinks:visit.playAgain"
        $("#play-again-status").text "Your opponent declined to play again."
    
    # Handle notification of unavailability of a user to accept or reject
    # the invitation to play another game, indicating this result to the inviting user.
    cannotPlayAgain: (data) ->
      return if data.user_id == App.User.id
      $(document).off "turbolinks:visit.playAgain"
      $("#play-again-status").text "Your opponent did not respond or is otherwise
                                    unavailable to play again."
    
    # Handle notification of cancellation of the invitation to play another game,
    # indicating this result to the invited user, clearing the timeout, and
    # removing the relevant page-load handler.
    cancelPlayAgain: (data) ->
      return if data.user_id == App.User.id
      clearTimeout @playAgainTimeout
      $(document).off "turbolinks:visit.playAgain"
      $("#play-again-request").text "Your opponent canceled the invitation to play again."

# Send a request to play another game if the user clicks the play-again button,
# which appears beneath games that have recently been completed. Also, indicate
# to the user that the opponent's response is being awaited, and provide a 'cancel'
# button, which when clicked will cancel the request to play again.
$(document).on "click", ".play-again", (event) ->
  gameId = $(".game").data("id")
  $(this).parent().replaceWith '
    <section id="play-again-status">
      <p>Awaiting response from opponent...</p>
      <p><button id="cancel-play-again" class="btn btn-default">Cancel</button></p>
    </section>'
  App.gameSubscriptions[gameId].perform "request_play_again"
  $(document).one "turbolinks:visit.playAgain", ->
    App.gameSubscriptions[gameId].perform "cancel_play_again"
  $("#cancel-play-again").click ->
    $("#play-again-status").remove()
    $(document).off "turbolinks:visit.playAgain"
    App.gameSubscriptions[gameId].perform "cancel_play_again"