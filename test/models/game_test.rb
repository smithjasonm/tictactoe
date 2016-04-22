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
