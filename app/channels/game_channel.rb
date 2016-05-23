class GameChannel < ApplicationCable::Channel
  include ActionView::Helpers::DateHelper
  include Rails.application.routes.url_helpers
  
  def subscribed
    game = Game.find(params[:id])
    stream_for game
  end
  
  def make_play(data)
    game = Game.find(data['id'])
    return unless game.ongoing? && current_user.id == game.whose_turn.id
                            
    p = data['play']
    play = game.make_play(p['number'], p['x'], p['y'])
    
    broadcast = {
      action: 'make_play',
      userId: current_user.id,
      status: game.status,
      lastActivity: "Last activity #{ time_ago_in_words(game.updated_at) } ago",
      latestPlay: {
        x: play.x,
        y: play.y,
        player: play.player,
        number: play.number
      }
    }
    
    GameChannel.broadcast_to game, broadcast
    
    rescue IncompatibleGameStatusError, InvalidPlayNumberError,
                                      PositionUnavailableError => e
      return
    rescue ActiveRecord::RecordInvalid => invalid
      return
  end
  
  # Request to play another game. Include a time of expiration of the request
  # to prevent unreasonable delays.
  def request_play_again(data)
    game = Game.find(params[:id])
    user_id = data['user_id']
    GameChannel.broadcast_to game, user_id: user_id, action: 'request_play_again',
                                   expires: Time.now.to_i + 60
  end
  
  # Accept a request to play another game; if the expiration time has passed, however,
  # reject the request. Include in the message of acceptance the location of the new game.
  def confirm_play_again(data)
    expires = Time.at(data['expires'])
    if expires < Time.now
      reject_play_again
      return
    end
    game = Game.find(params[:id])
    user_id = data['user_id']
    new_game = Game.create player1_id: game.player1_id, player2_id: game.player2_id
    GameChannel.broadcast_to game, action: 'confirm_play_again', user_id: user_id,
                                 location: game_path(new_game)
  end
  
  # Reject a request to play another game.
  def reject_play_again(data)
    game = Game.find(params[:id])
    user_id = data['user_id']
    GameChannel.broadcast_to game, action: 'reject_play_again', user_id: user_id
  end
end