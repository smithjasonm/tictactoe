# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class WaitingGamesChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'waiting_games'
  end
end
