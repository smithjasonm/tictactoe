require 'test_helper'

class GameTest < ActiveSupport::TestCase
  setup do
    @game = games(:one)
  end
  
  test "should not save game without a status" do
    @game.status = nil
    assert_not @game.save
  end
  
  test "should not save game with invalid status" do
    @game.status = -1
    assert_not @game.save
    @game.status = 6
    assert_not @game.save
  end
  
  test "should not accept two plays in one position" do
    game2 = games(:two)
    game2.play(1, 1, 1)
    assert_throws InvalidPlayError do
      game2.play(2, 1, 1)
    end
  end
  
  test "should set status to P1_WON if player 1 has won" do
    game2 = games(:two)
    assert_equal Game::PENDING, game2.status
    game2.play(1, 0, 0)
    game2.play(2, 1, 0)
    game2.play(1, 0, 1)
    game2.play(2, 2, 0)
    game2.play(1, 0, 2)
    assert_equal Game::P1_WON, game2.status
  end
  
  test "should set status to P2_WON if player 2 has won" do
    game2 = games(:two)
    assert_equal Game::PENDING, game2.status
    game2.play(1, 0, 0)
    game2.play(2, 2, 0)
    game2.play(1, 0, 1)
    game2.play(2, 0, 2)
    game2.play(1, 2, 2)
    game2.play(2, 1, 1)
    assert_equal Game::P2_WON, game2.status
  end
  
  test "should set status to DRAW if game is drawn" do
    game2 = games(:two)
    assert_equal Game::PENDING, game2.status
    game2.play(1, 1, 1)
    game2.play(2, 0, 0)
    game2.play(1, 2, 0)
    game2.play(2, 0, 2)
    game2.play(1, 0, 1)
    game2.play(2, 2, 1)
    game2.play(1, 1, 0)
    game2.play(2, 1, 2)
    game2.play(1, 2, 2)
    assert_equal Game::DRAW, game2.status
  end
  
  test "should set status to P1_FORFEIT if player 1 foreits" do
    assert_equal Game::PENDING, @game.status
    @game.player1_forfeits
    assert_equal Game::P1_FORFEIT, @game.status
  end
  
  test "should set status to P2_FORFEIT if player 2 forfeits" do
    assert_equal Game::P2_FORFEIT, @game.status
    @game.player2_forfeits
    assert_equal Game::P2_FORFEIT, @game.status
  end
  
  test "should not allow play to be made for non-pending games" do
    flunk
  end
  
  test "should not allow forfeit if game is already completed" do
    flunk
  end
end
