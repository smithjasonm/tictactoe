class GameChannel < ApplicationCable::Channel
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
      user_id: current_user.id,
      status: game.status,
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
end