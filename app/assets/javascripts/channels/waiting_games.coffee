App.waiting_games = App.cable.subscriptions.create "WaitingGamesChannel",
  received: (data) ->
    # Reload page if there is an update to waiting games not initiated by current user
    # and a list of waiting games is displayed on the current page.
    if data.user_id != App.User.id && $(".waiting-games").length > 0 
      Turbolinks.visit window.location
