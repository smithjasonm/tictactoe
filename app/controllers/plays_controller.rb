class PlaysController < ApplicationController
  # GET /games/1/plays.json
  def index
    @plays = Game.find(params[:game_id]).plays
  end

  # POST /games/1/plays.json
  def create
    @game = Game.find(params[:game_id])
    unless @game.pending? && @game.player2_id.present? &&
                            user_session.current_user.id == @game.whose_turn.id
      head :forbidden
      return
    end
    p = Play.new(play_params)
    respond_to do |format|
      begin
        @play = @game.make_play(p.number, p.x, p.y)
        format.html { redirect_to @game }
        format.json { render :show, status: :created, location: @play }
      rescue IncompatibleGameStatusError, InvalidPlayNumberError,
                                          PositionUnavailableError => e
        format.html { render 'games/show' }
        format.json { render json: e.message, status: :unprocessable_entity }
      rescue ActiveRecord::RecordInvalid => invalid
        format.html { render 'games/show' }
        render json: invalid.record.errors, status: :unprocessable_entity
      end
    end
  end

  private
  
    # Whitelist parameters.
    def play_params
      params.require(:play).permit(:number, :x, :y)
    end
end
