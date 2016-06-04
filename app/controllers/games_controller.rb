class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy]

  # GET /games
  # GET /games.json
  def index
    @user = user_session.current_user
    @new_game = Game.new(player1_id: @user.id)
    @ongoing_games = @user.ongoing_games
    @waiting_games = Game.waiting_games(@user)
    @user_waiting_game = @user.waiting_game
    @recent_games = @user.completed_games(5)
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
      @next_play_number = @game.next_play_number
      @new_game = nil
    else
      @new_game = Game.new(player1_id: user_id)
    end
    @opponent = user_id == @game.player1_id ? @game.player2 : @game.player1
    @pair_record = user.game_record(@opponent) if @opponent
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
    
    @game.save!
    
    # Broadcast message to clients directing them to update their lists
    # of waiting games, using the html included. Use a new user as a dummy
    # for the nested join_game_form partial, which requires the potential joining
    # user's ID, as the actual value will be set by the client.
    waiting_game_html = render_to_string partial: 'waiting_game', object: @game,
                                          locals: { user: User.new }
    ActionCable.server.broadcast 'waiting_games', action: 'add_game',
                                                 user_id: user.id,
                                                 game_id: @game.id,
                                                    html: waiting_game_html
    
    respond_to do |format|
      format.html { redirect_to @game }
      format.json { render :show, status: :created, location: @game }
    end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
    # Allow updates only of pending games
    if @game.completed?
      head :forbidden
      return
    end
    
    user_id = user_session.current_user.id
    game_params = params.require(:game).permit(:player2_id, :status)
    if game_params[:status]
      # Allow status updates only of ongoing games
      unless @game.ongoing?
        head :forbidden
        return
      end
      
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
      
      # Broadcast message to clients directing them to update their lists
      # of waiting games.
      ActionCable.server.broadcast 'waiting_games', action: 'remove_game',
                                                   user_id: user_id,
                                                   game_id: @game.id
    else
      head :bad_request
      return
    end
    
    # Broadcast notice of game update to clients along with current game status.
    GameChannel.broadcast_to @game, user_id: user_id, status: @game.status,
                                                      action: 'update_game'
    
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
    
    # Broadcast message to clients directing them to update their lists
    # of waiting games.
    ActionCable.server.broadcast 'waiting_games', action: 'remove_game',
                                                 user_id: user_id,
                                                 game_id: @game.id
    
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
