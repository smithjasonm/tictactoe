$(document).on "turbolinks:load", ->
  $game = $(".game")
  if $game.length > 0
    App.gameSubscription = App.cable.subscriptions.create {
                                                            channel: "GameChannel"
                                                            id: $game.data("id")
                                                          },
      make_play: (data) ->
        @perform "make_play", data
      
      received: (data) ->
        @updateGame data
      
      updateGame: (data) ->
        if data.status == 0
          if data.user_id != App.User.id
            App.Game.addPlay data.latestPlay
            $(".whose_turn").text "Your turn"
            $game.addClass "playable"
          $("#play_number").val(data.latestPlay.number + 1)
        else
          Turbolinks.visit(window.location)