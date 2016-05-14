require 'test_helper'

class GameTest < ActiveSupport::TestCase
  test "should save game with valid configuration" do
    game = Game.new({ player1: users(:one), player2: users(:two) })
    assert game.save
  end
  
  test "should delete all associated plays when game is deleted" do
    game = games(:pending_game)
    game_play_count = game.plays.size
    assert game_play_count > 0
    assert_difference "Play.count", -game_play_count do
      game.destroy!
    end
  end
  
  test "new games should have initial status of PENDING" do
    game = Game.new({ player1: users(:one), player2: users(:two) })
    assert_equal Game::PENDING, game.status
  end
  
  test "should not save game with invalid status" do
    game = games(:pending_game)
    game.status = nil
    assert_not game.save
    game.status = -1
    assert_not game.save
    game.status = 6
    assert_not game.save
    game.status = 1.5
    assert_not game.save
    game.status = "a"
    assert_not game.save
  end
  
  test "should accept and save valid play" do
    game = games(:new_game)
    play = game.make_play(1, 1, 1)
    assert play.persisted?
  end
  
  test "should not accept two plays in one position" do
    game = games(:new_game)
    game.make_play(1, 1, 1)
    assert_raise PositionUnavailableError do
      game.make_play(2, 1, 1)
    end
  end
  
  test "should not acccept play with invalid number" do
    game = games(:new_game)
    game.make_play(1, 1, 1)
    assert_raise InvalidPlayNumberError do
      game.make_play(1, 0, 0)
    end
    game.reload
    assert_raise InvalidPlayNumberError do
      game.make_play(3, 0, 0)
    end
  end
  
  test "should not accept play with invalid position" do
    game = games(:new_game)
    assert_raise InvalidPlayPositionError do
      game.make_play(1, 0, 3)
    end
    assert_raise InvalidPlayPositionError do
      game.make_play(1, 3, 0)
    end
    assert_raise InvalidPlayPositionError do
      game.make_play(1, 0, -1)
    end
    assert_raise InvalidPlayPositionError do
      game.make_play(1, -1, 0)
    end
    assert_raise InvalidPlayPositionError do
      game.make_play(1, 0, 0.5)
    end
    assert_raise InvalidPlayPositionError do
      game.make_play(1, 0.5, 0)
    end
  end
  
  test "should set status to P1_WON if player 1 has won" do
    game = games(:new_game)
    assert_equal Game::PENDING, game.status
    make_player1_win game
    assert_equal Game::P1_WON, game.status
  end
  
  test "should set status to P2_WON if player 2 has won" do
    game = games(:new_game)
    assert_equal Game::PENDING, game.status
    make_player2_win game
    assert_equal Game::P2_WON, game.status
  end
  
  test "should set status to DRAW if game is drawn" do
    game = games(:new_game)
    assert_equal Game::PENDING, game.status
    draw_game game
    assert_equal Game::DRAW, game.status
  end
  
  test "should set status to P1_FORFEIT if player 1 forfeits" do
    game = games(:pending_game)
    assert_equal Game::PENDING, game.status
    game.player1_forfeits
    assert_equal Game::P1_FORFEIT, game.status
  end
  
  test "should set status to P2_FORFEIT if player 2 forfeits" do
    game = games(:pending_game)
    assert_equal Game::PENDING, game.status
    game.player2_forfeits
    assert_equal Game::P2_FORFEIT, game.status
  end
  
  test "should not allow play to be made for game forfeited by player 1" do
    game = games(:new_game)
    game.player1_forfeits
    assert_raise IncompatibleGameStatusError do
      game.make_play(1, 1, 1)
    end
  end
  
  test "should not allow play to be made for game forfeited by player 2" do
    game = games(:new_game)
    game.player2_forfeits
    assert_raise IncompatibleGameStatusError do
      game.make_play(1, 1, 1)
    end
  end
  
  test "should not allow play to be made for drawn game" do
    game = games(:new_game)
    draw_game game
    assert_raise IncompatibleGameStatusError do
      game.make_play(1, 1, 1)
    end
  end
  
  test "should not allow forfeit if game is drawn" do
    game = games(:new_game)
    draw_game game
    assert_raise IncompatibleGameStatusError do
      game.player1_forfeits
    end
    assert_raise IncompatibleGameStatusError do
      game.player2_forfeits
    end
  end
  
  test "should not allow forfeit if game has been won by player 1" do
    game = games(:new_game)
    make_player1_win game
    assert_raise IncompatibleGameStatusError do
      game.player1_forfeits
    end
    assert_raise IncompatibleGameStatusError do
      game.player2_forfeits
    end
  end

  test "should not allow forfeit if game has been won by player 2" do
    game = games(:new_game)
    make_player2_win game
    assert_raise IncompatibleGameStatusError do
      game.player1_forfeits
    end
    assert_raise IncompatibleGameStatusError do
      game.player2_forfeits
    end
  end
  
  test "should not allow player 2 to forfeit if player 1 has forfeited" do
    game = games(:new_game)
    game.player1_forfeits
    assert_raise IncompatibleGameStatusError do
      game.player2_forfeits
    end
  end
  
  test "should not allow player 1 to forfeit if player 2 has forfeited" do
    game = games(:new_game)
    game.player2_forfeits
    assert_raise IncompatibleGameStatusError do
      game.player1_forfeits
    end
  end
  
  test "should allow user to resign from game user is playing" do
    game = games(:new_game)
    assert_equal Game::PENDING, game.status
    game.resign(users(:one))
    assert_equal Game::P1_FORFEIT, game.status
  end
  
  test "should not allower user to resign from game user is not playing" do
    game = games(:new_game)
    user = users(:three)
    assert_not_equal user, game.player1
    assert_not_equal user, game.player2
    assert_raise InvalidUserError do
      game.resign(user)
    end
  end
  
  test "whose_turn should return player whose turn it is" do
    game = games(:pending_game)
    assert_equal users(:one).id, game.whose_turn.id
    game = games(:forfeited_game)
    assert_nil game.whose_turn
  end
  
  test "should return winning player if one exists" do
    game = games(:forfeited_game) # Forfeited by player1 (user :one)
    assert_equal users(:two).id, game.winner.id
  end
  
  test "should return nil for winning player if one does not exist" do
    game = games(:pending_game)
    assert_nil game.winner
    game = games(:waiting_game)
    assert_nil game.winner
    game = games(:new_game)
    assert_nil game.winner
  end
  
  test "should return whether game is pending" do
    assert games(:pending_game).pending?
    assert games(:new_game).pending?
    assert games(:waiting_game).pending?
    assert_not games(:forfeited_game).pending?
  end
  
  test "should return whether game is ongoing" do
    assert games(:pending_game).ongoing?
    assert games(:new_game).ongoing?
    assert_not games(:waiting_game).ongoing?
    assert_not games(:forfeited_game).ongoing?
  end
  
  test "should return whether game is waiting" do
    assert games(:waiting_game).waiting?
    assert_not games(:pending_game).waiting?
    assert_not games(:new_game).waiting?
    assert_not games(:forfeited_game).waiting?
  end
  
  test "should return whether game is completed" do
    assert games(:forfeited_game).completed?
    assert_not games(:pending_game).completed?
    assert_not games(:new_game).completed?
    assert_not games(:waiting_game).completed?
  end
  
  private
  
    # Cause the given new game to be drawn
    def draw_game(game)
      game.make_play(1, 1, 1)
      game.make_play(2, 0, 0)
      game.make_play(3, 2, 0)
      game.make_play(4, 0, 2)
      game.make_play(5, 0, 1)
      game.make_play(6, 2, 1)
      game.make_play(7, 1, 0)
      game.make_play(8, 1, 2)
      game.make_play(9, 2, 2)
      game
    end
    
    # Make player 1 win the given new game
    def make_player1_win(game)
      game.make_play(1, 0, 0)
      game.make_play(2, 1, 0)
      game.make_play(3, 0, 1)
      game.make_play(4, 2, 0)
      game.make_play(5, 0, 2)
      game
    end
    
    # Make player 2 win the given new game
    def make_player2_win(game)
      game.make_play(1, 0, 0)
      game.make_play(2, 2, 0)
      game.make_play(3, 0, 1)
      game.make_play(4, 0, 2)
      game.make_play(5, 2, 2)
      game.make_play(6, 1, 1)
      game
    end
end
