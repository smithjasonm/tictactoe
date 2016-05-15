# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# Send play to server when an empty position of a pending game is clicked.
$(document).on "click", ".game.playable .position.empty", (event) ->
  console.log("clicked position")
  position = $(this).data()
    
  $("#play_x").val position.x
  $("#play_y").val position.y
  $("#new_play").submit()