# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on "ready page:load", ->
  # Send play to server when an empty position of a pending game is clicked.
  $(".game.playable").on "click", ".position.empty", (event) ->
    position = $(this).data()
    
    $("#play_x").val position.x
    $("#play_y").val position.y
    $("#new_play").submit()
  
  # Update game view when play is made or game is quit
  $("#new_play, .quit_game").on "ajax:success", (e, data, status, xhr) ->
    Turbolinks.visit location
    
    ###
    x = data.x
    y = data.y
    cellSelector = ".position[data-x='#{x}'][data-y='#{y}']"
    $cell = $(".game").find cellSelector
    $cell.text = if data.player === 1 then 'x' else 'o'
    ###
  
  # Handle errors creating play or quitting game
  $("#new_play, .quit_game").on "ajax:error", (e, data, status, xhr) ->
    console.log data