class PlaysController < ApplicationController
  # GET /games/1/plays.json
  def index
    @plays = Game.find(params[:game_id]).plays
  end

  # POST /games/1/plays.json
  def create
    game = Game.find(params[:game_id])
    p = Play.new(play_params)
    begin
      @play = game.make_play(p.number, p.x, p.y)
      render :show, status: :created, location: game
    rescue IncompatibleGameStatusError, InvalidPlayNumberError,
                                        PositionUnavailableError => e
      render json: e.message, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => invalid
      render json: invalid.record.errors, status: :unprocessable_entity
    end
  end

  private
  
    # Whitelist parameters.
    def play_params
      params.require(:play).permit(:number, :x, :y)
    end
end
