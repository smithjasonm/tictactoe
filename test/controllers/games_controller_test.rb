require 'test_helper'

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:pending_game)
    @user = users(:one)
  end

  test "should get index" do
    log_in_as @user
    get games_url
    assert_response :success
  end
  
  test "should redirect from index to login if not logged in" do
    get games_url
    assert_redirected_to login_path
  end

  test "should create game" do
    user2 = users(:two)
    log_in_as user2
    assert_difference('Game.count') do
      post games_url, params: { game: { player1_id: user2.id } }
    end

    assert_redirected_to game_path(Game.last)
  end
  
  test "should redirect from create game to login if not logged in" do
    assert_no_difference('Game.count') do
      post games_url, params: { game: { player1_id: @user.id } }
    end
    
    assert_redirected_to login_path
  end

  test "should show game" do
    log_in_as @user
    get game_url(@game)
    assert_response :success
  end
  
  test "should redirect from show game to login if not logged in" do
    get game_url(@game)
    assert_redirected_to login_path
  end

  test "should add second player" do
    user2 = users(:two)
    waiting_game = games(:waiting_game)
    log_in_as user2
    
    patch game_url(waiting_game), params: { game: { player2_id: user2.id } }
    waiting_game.reload
    
    assert_equal user2.id, waiting_game.player2_id
    assert_redirected_to game_path(waiting_game)
  end
  
  test "should redirect from add second player to login if not logged in" do
    user2 = users(:two)
    waiting_game = games(:waiting_game)
    
    patch game_url(waiting_game), params: { game: { player2_id: user2.id } }
    waiting_game.reload
    
    assert_nil waiting_game.player2_id
    assert_redirected_to login_path
  end
  
  test "should accept player resignation" do
    log_in_as @user
    
    patch game_url(@game), params: { game: { status: Game::P1_FORFEIT } }
    @game.reload
    
    assert_equal Game::P1_FORFEIT, @game.status
    assert_redirected_to game_path(@game)
  end
  
  test "should redirect from player resignation to login if not logged in" do
    patch game_url(@game), params: { game: { status: Game::P1_FORFEIT } }
    @game.reload
    
    assert_equal Game::PENDING, @game.status
    assert_redirected_to login_path
  end

  test "should destroy game" do
    log_in_as @user
    assert_difference('Game.count', -1) do
      delete game_url(games(:waiting_game))
    end

    assert_redirected_to games_path
  end
  
  test "should redirect from destroy game to login if not logged in" do
    assert_no_difference('Game.count') { delete game_url(games(:waiting_game)) }
    assert_redirected_to login_path
  end
end
