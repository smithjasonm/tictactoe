class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy, :quit]

  # GET /games
  # GET /games.json
  def index
    @user = user_session.current_user
    @new_game = Game.new(player1_id: @user.id)
    @ongoing_games = @user.ongoing_games
    @waiting_games = Game.waiting_games(@user)
    @user_waiting_game = @user.waiting_game
    @completed_games = @user.completed_games
    @game_record = @user.game_record
  end

  # GET /games/1
  # GET /games/1.json
  def show
    user = user_session.current_user
    user_id = user.id
    unless user_id == @game.player1_id || user_id == @game.player2_id
      head :forbidden
      return
    end
    if @game.pending?
      @next_play = Play.new
      @next_play.number = @game.next_play_number
      @new_game = nil
    else
      @new_game = Game.new(player1_id: user_id)
    end
    @opponent = user_id == @game.player1_id ? @game.player2 : @game.player1
    @pair_record = user.game_record(@opponent) if @opponent
  end

  # GET /games/new
  def new
    @game = Game.new
  end

  # GET /games/1/edit
  def edit
  end

  # POST /games
  # POST /games.json
  def create
    game_params = params.require(:game).permit(:player1_id)
    @game = Game.new(game_params)
    user = user_session.current_user
    
    unless user.id == @game.player1_id && user.waiting_game.nil?
      head :forbidden
      return
    end
    
    respond_to do |format|
      if @game.save
        format.html { redirect_to @game }
        format.json { render :show, status: :created, location: @game }
      else
        format.html { render :new }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
    user_id = user_session.current_user.id
    game_params = params.require(:game).permit(:player2_id, :status)
    if game_params[:status]
      case game_params[:status].to_i
      when Game::P1_FORFEIT
        unless user_id == @game.player1.id
          head :forbidden
          return
        end
        @game.player1_forfeits
      when Game::P2_FORFEIT
        unless user_id == @game.player2.id
          head :forbidden
          return
        end
        @game.player2_forfeits
      else
        head :forbidden
        return
      end
    elsif game_params[:player2_id]
      player2_id = game_params[:player2_id].to_i
      unless @game.player2_id.nil? && user_id == player2_id
        head :forbidden
        return
      end
      @game.update!(player2_id: player2_id)
    else
      head :bad_request
      return
    end
    respond_to do |format|
      format.html { redirect_to @game }
      format.json { render :show, status: :ok, location: @game }
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    user_id = user_session.current_user.id
    unless user_id == @game.player1_id && @game.player2.nil?
      head :forbidden
      return
    end
    @game.destroy
    respond_to do |format|
      format.html { redirect_to games_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end
end
