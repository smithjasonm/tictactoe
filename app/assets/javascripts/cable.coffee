# On page load, if user is logged in, create an Action Cable consumer if one
# does not already exist, and ensure it is connected. If user is not logged in
# and a consumer exists, disconnect the consumer.
$(document).on "turbolinks:load", ->
  if App.User.id?
    App.cable ||= ActionCable.createConsumer()
    App.cable.ensureActiveConnection()
  else
    App.cable?.disconnect()
    