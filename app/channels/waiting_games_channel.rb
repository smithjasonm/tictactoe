# Notifies subscribers of each addition and removal of a waiting game.
class WaitingGamesChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'waiting_games'
  end
end
