module GamesHelper
  # Render a cell on a game board
  def game_cell(game, row, col)
    position_state = game.position_state(col, row)
    
    case position_state
    when 1
      cell_value = 'X'
    when 2
      cell_value = 'O'
    else
      cell_value = ''
    end
    
    cell_class = "position #{ position_state.nil? ? 'empty' : 'filled' }"
    cell_class += ' winning' if game.winning_play_coordinates.try :include?, [col, row]
    
    cell_data = { x: col, y: row}
    
    game_cell = { cell_class: cell_class, cell_data: cell_data, cell_value: cell_value }
    render partial: 'games/game_cell', object: game_cell
  end
  
  def game_class(game)
    result = 'game'
    if game.ongoing? && game.whose_turn.id == user_session.current_user.id
      result += ' playable'
    end
    return result
  end
  
  # Return handle of current user's opponent in given game if present
  def opponent_handle(game)
    return nil if game.player2_id.nil?
    user_session.current_user.id == game.player1_id ? game.player2.handle :
                                                      game.player1.handle
  end
  
  # Return appropriate label to indicate which player's turn it is according to
  # whether it is the current user's turn.
  def whose_turn(game)
    return nil unless game.pending? && game.player2_id.present?
    player = game.whose_turn
    player.id == user_session.current_user.id ? 'Your turn' : "#{ player.handle }'s turn"
  end
  
  def game_status_text(game)
    user_id = user_session.current_user.id
    case game.status
    when Game::PENDING
      'Waiting for second player...' if game.waiting?
    when Game::P1_WON
      user_id == game.player1_id ? 'You won!' : 'You lost'
    when Game::P2_WON
      user_id == game.player2_id ? 'You won!' : 'You lost'
    when Game::DRAW
      'Draw'
    when Game::P1_FORFEIT
      user_id == game.player1_id ? 'You resigned' : "#{ game.player2.handle } resigned"
    when Game::P2_FORFEIT
      user_id == game.player2_id ? 'You resigned' : "#{ game.player1.handle } resigned"
    end
  end
  
  # Return appropriate text to indicate whether current user won, lost,
  # or drew completed game."
  def game_result(completed_game)
    winner = completed_game.winner
    return 'Draw' unless winner
    winner.id == user_session.current_user.id ? 'Won' : 'Lost'
  end
  
  # Return title for game according to whether it has a second player.
  # Optionally, include indicators of which user plays X and which O.
  def game_title(game, with_indicators = false)
    handle1 = current_user_is_player1?(game) ? 'You' : game.player1.handle
    if current_user_is_player2?(game)
      handle2 = 'You'
    else
      handle2 = game.player2 ? game.player2.handle : '?'
    end
    
    if with_indicators
      handle1 = <<-HANDLE1.html_safe
        <span class="nowrap">
          #{h handle1}
          (<span class="indicator">X</span>)
        </span>
      HANDLE1
      
      handle2 = <<-HANDLE2.html_safe
        <span class="nowrap">
          #{h handle2}
          (<span class="indicator">O</span>)
        </span>
      HANDLE2
    end
    
    handle1 + ' vs. ' + handle2
  end
  
  # Determine whether current user is player 1 of given game
  def current_user_is_player1?(game)
    user_session.current_user.id == game.player1_id
  end
  
  # Determine whether current user is player 2 of given game
  def current_user_is_player2?(game)
    user_session.current_user.id == game.player2_id
  end
  
  # Render button to enable user to delete or resign from pending game or start a new one
  # if the current game is over.
  def quit_or_new_game_button(game, new_game)
    if game.pending?
      locals = { game: game }
      if game.player2_id.nil?
        render partial: 'games/delete_game_form', locals: locals
      else
        render partial: 'games/resign_game_form', locals: locals
      end
    else
      <<-RESULT.html_safe
        <p>
          <button class="play-again btn btn-default" style="display: none">
            Play again
          </button>
        </p>
      RESULT
    end
  end
  
  # Return status for edit-game form, according to whether current user is player1
  def resign_status(game)
    user_session.current_user.id == game.player1_id ? Game::P1_FORFEIT : Game::P2_FORFEIT
  end
end
