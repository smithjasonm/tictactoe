# Handles user interaction with game boards. Adds plays to game boards and sends them
# to the server.
class GameManager
  
  constructor: ->
    @addClickHandler()
  
  # Add a play to the game board associated with the given game ID, using the
  # play information provided.
  addPlay: (gameId, play) ->
  
    # Find the cell to which to add an "X" or "O."
    $game = $(".game[data-id='#{gameId}']")
    xSelector = "[data-x='#{play.x}']"
    ySelector = "[data-y='#{play.y}']"
    cellSelector = xSelector + ySelector
    $cell = $game.find cellSelector
    
    # Update the cell with the appropriate symbol.
    symbol = if play.player == 1 then 'X' else 'O'
    @updateCell $cell, symbol
  
  # Private
  
  # Add an "X" or "O" to a cell and mark it as filled.
  updateCell: ($cell, symbol) ->
    $cell.text(symbol).removeClass("empty").addClass("filled")
  
  # Make a play at the given game cell and send its representation to the server.
  createPlay: ($gameCell) ->
    $game = $gameCell.closest(".game")
    
    # Extract data
    position = $gameCell.data()
    gameId = $game.data("id")
    nextPlayNumber = $game.data("next-play-number")
    
    # Update the cell with the appropriate symbol.
    symbol = if nextPlayNumber % 2 == 1 then "X" else "O"
    @updateCell $gameCell, symbol
    
    # Prevent further user interaction with game board.
    $game.removeClass "playable"
    
    # Submit new-play form (not currently used).
    # $("#play_x").val position.x
    # $("#play_y").val position.y
    # $("#new_play").submit()
    
    # Send play to server.
    params =
      id: gameId
      play:
        x: position.x
        y: position.y
        number: nextPlayNumber
    App.gameChannelClient.subscriptions[gameId].perform "make_play", params
  
  # Add handler to send play to server when an empty position of a pending game is
  # clicked, provided that the clicked game is not a preview.
  addClickHandler: ->
    $(document).on "click", ".game.playable .position.empty", (event) =>
      $cell = $(event.currentTarget)
      @createPlay $cell if $cell.closest(".game-preview").length == 0

window.App ||= {}
App.gameManager = new GameManager