# Receives and transmits game updates. Each channel subscription is for a single game.
class GameChannel < ApplicationCable::Channel
  include ActionView::Helpers::DateHelper
  include Rails.application.routes.url_helpers
  
  # On channel subscription, stream updates for specified game.
  def subscribed
    @game = Game.find(params[:id])
    stream_for @game
  end
  
  # Make a play.
  def make_play(data)
    
    # Update the stored game instance.
    @game.reload
    
    # Only permit a play to be made if the game is ongoing and it is the turn
    # of the user who is requesting to make the play.
    return unless @game.ongoing? && current_user.id == @game.whose_turn.id
    
    # Make the play.
    p = data['play']
    play = @game.make_play(p['number'], p['x'], p['y'])
    
    # Broadcast the play to listening clients.
    broadcast = {
      action: 'make_play',
      userId: current_user.id,
      status: @game.status,
      lastActivity: "Last activity #{ time_ago_in_words(@game.updated_at) } ago",
      latestPlay: {
        x: play.x,
        y: play.y,
        player: play.player,
        number: play.number
      }
    }
    GameChannel.broadcast_to @game, broadcast
    
    # If any recognized errors occur while making the play, do nothing.
    rescue IncompatibleGameStatusError, InvalidPlayNumberError,
                                      PositionUnavailableError => e
      return
    rescue ActiveRecord::RecordInvalid => invalid
      return
  end
  
  # Request to play another game. Include a time of expiration of the request
  # to prevent unreasonable delays.
  def request_play_again
    GameChannel.broadcast_to @game, user_id: current_user.id,
                                     action: 'request_play_again',
                                    expires: Time.now.to_i + 60
  end
  
  # Accept a request to play another game; if the expiration time has passed, however,
  # do nothing. Include in the message of acceptance the location of the new game.
  def confirm_play_again(data)
    expires = Time.at(data['expires'])
    return if expires < Time.now
    
    new_game = Game.create player1_id: @game.player1_id, player2_id: @game.player2_id
    GameChannel.broadcast_to @game, action: 'confirm_play_again',
                                   user_id: current_user.id,
                                  location: game_path(new_game)
  end
  
  # Reject a request to play another game.
  def reject_play_again
    GameChannel.broadcast_to @game, action: 'reject_play_again', user_id: current_user.id
  end
  
  # Indicate that the user invited to play another game is no longer on the game page and
  # hence cannot accept or reject the invitation.
  def cannot_play_again
    GameChannel.broadcast_to @game, action: 'cannot_play_again', user_id: current_user.id
  end
  
  # Cancel a request to play another game.
  def cancel_play_again
    GameChannel.broadcast_to @game, action: 'cancel_play_again', user_id: current_user.id
  end
end