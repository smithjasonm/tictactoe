# Handles addition and removal of waiting games to and from the list of waiting games.
# Updates the list according to messages received from server, without reloading page.
App.waiting_games = App.cable.subscriptions.create "WaitingGamesChannel",
  # Handle receipt of data from server.
  received: (data) ->
    Turbolinks.clearCache()
    
    # Proceed only if action was not initiated by current user.
    return if data.user_id == App.User.id
    
    $waiting_games = $("#waiting-games")
    
    # Proceed only if current user is on a page displaying waiting games.
    return if $waiting_games.length == 0
    
    # Take action directed by server.
    switch data.action
      # Add a game to the list of waiting games. If there were previously no waiting
      # games, first remove the text indicating so. Set the user ID in the
      # join-game form received from the server to the current user's ID,
      # as this will not be set by the server.
      when 'add_game'
        $("#no-waiting-games").remove()
        $waiting_games.prepend data.html
        $("#waiting-game-#{data.game_id} input[name='game[player2_id]']").val App.User.id
      
      # Remove a game from the list of waiting games. If, after its removal, no more
      # waiting games remain, insert text indicating so.
      when 'remove_game'
        $("#waiting-game-#{data.game_id}").remove()
        if $(".waiting-game").length == 0
          $waiting_games.html '<p id="no-waiting-games">No waiting games</p>'