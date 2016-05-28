# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.App || (window.App = {})

App.Game =
  addPlay: (gameId, play) ->
    $cell = $(".game[data-id='#{ gameId }'] [data-x='#{ play.x }'][data-y='#{ play.y }']")
    symbol = if play.player == 1 then 'X' else 'O'
    $cell.text(symbol).removeClass("empty").addClass("filled")

# Send play to server when an empty position of a pending game is clicked.
$(document).on "click", ".game.playable .position.empty", (event) ->
  $this = $(this)
  return if $this.closest(".game-preview").length > 0
  
  position = $this.data()
  $game = $this.closest(".game")
  gameId = $game.data("id")
  nextPlayNumber = $game.data("next-play-number")
  
  play =
    x: position.x
    y: position.y
    player: if nextPlayNumber % 2 == 1 then 1 else 2
  
  App.Game.addPlay gameId, play
  
  $game.removeClass "playable"
  
#   $("#play_x").val position.x
#   $("#play_y").val position.y
#   $("#new_play").submit()
  
  data =
    id: gameId
    play:
      x: position.x
      y: position.y
      number: nextPlayNumber
  
  App.gameSubscriptions[gameId].perform "make_play", data