# Handles addition and removal of waiting games to and from the list of waiting games.
# Updates the list according to messages received from server, without reloading page.
class WaitingGamesChannelClient
  
  # Properties to be mixed into the waiting-games channel subscription
  subscriptionMixin:
        
    # On permanent disconnection from server, unsubscribe.
    disconnected: ({willAttemptReconnect}) =>
      @removeSubscription() unless willAttemptReconnect
    
    # Handle receipt of data from server.
    received: (data) ->
      Turbolinks.clearCache()
      
      # Proceed only if the user did not initiate the action and is on a page
      # displaying waiting games.
      return if data.user_id == App.User.id || $("#waiting-games").length == 0
      
      # Take action directed by server.
      switch data.action
        when 'add_game'    then @addGame data
        when 'remove_game' then @removeGame data
    
    # Add a game to the list of waiting games. If there were previously no waiting
    # games, first remove the text indicating so. Set the user ID in the
    # join-game form received from the server to the current user's ID,
    # as this will not be set by the server.
    addGame: (data) ->
      $("#no-waiting-games").remove()
      
      # If the user has a waiting game, insert the new waiting game after it;
      # otherwise, prepend the new waiting game to the list of waiting games.
      $userWaitingGame = $(".user-waiting-game")
      if $userWaitingGame.length > 0
        $userWaitingGame.after data.html
      else
        $("#waiting-games").prepend data.html
      
      $("#game_#{data.game_id}_player2_id").val App.User.id
    
    # Remove a game from the list of waiting games. If, after its removal, no more
    # waiting games remain, insert text indicating so. If the game to be removed
    # was created by the user, however, reload the page instead so that the
    # now ongoing game will be displayed as well.
    removeGame: (data) ->
      $game = $("#waiting-game-#{data.game_id}")
      
      if $game.hasClass("user-waiting-game")
        Turbolinks.visit(window.location)
      else
        $game.remove()
        if $(".waiting-game").length == 0
          $("#waiting-games").html '<p id="no-waiting-games">No waiting games</p>'
  
  constructor: ->
    @addPageLoadHandler()
  
  # Subscribe to the waiting-games channel
  createSubscription: ->
    @subscription = App.cable.subscriptions.create "WaitingGamesChannel",
                                                   @subscriptionMixin
  
  # Unsubscribe from the waiting-games channel
  removeSubscription: ->
    @subscription.unsubscribe()
    @subscription = null
  
  # Add page load handler, which will subscribe to the waiting-games channel
  # if there is an Action Cable connection and no existing subscription.
  addPageLoadHandler: ->
    $(document).on "turbolinks:load", =>
      @createSubscription() if App.cable and not @subscription

App.waitingGamesChannelClient = new WaitingGamesChannelClient