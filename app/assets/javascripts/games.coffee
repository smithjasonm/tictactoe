# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.App || (window.App = {})

App.Game =
  addPlay: (play) ->
    $cell = $(".game [data-x='#{ play.x }'][data-y='#{ play.y }']")
    symbol = if play.player == 1 then 'X' else 'O'
    $cell.text(symbol).removeClass("empty").addClass("filled")

# Send play to server when an empty position of a pending game is clicked.
$(document).on "click", ".game.playable .position.empty", (event) ->
  position = $(this).data()
  
  play =
    x: position.x
    y: position.y
    player: if $("#play_number").val() % 2 == 1 then 1 else 2
  
  App.Game.addPlay play
  
  $game = $(".game")
  $game.removeClass "playable"
  
  opponent_handle = $game.data("opponent-handle")
  $(".whose_turn").text "#{ opponent_handle }'s turn"
  
  # $("#play_x").val position.x
  # $("#play_y").val position.y
  # $("#new_play").submit()
  
  data =
    id: $game.data("id")
    play:
      x: position.x
      y: position.y
      number: +$("#play_number").val()
  
  App.gameSubscription.make_play data