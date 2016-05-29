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
  
  test "should not create game if user has waiting game" do
    log_in_as @user
    assert_no_difference('Game.count') do
      post games_url, params: { game: { player1_id: @user.id } }
    end
    
    assert_response :forbidden
  end
  
  test "should not create game with other user as player1" do
    log_in_as users(:two)
    assert_no_difference('Game.count') do
      post games_url, params: { game: { player1_id: users(:three).id } }
    end
    
    assert_response :forbidden
  end
  
  test "should not create game with second player" do
    user2 = users(:two)
    user3 = users(:three)
    log_in_as user2
    
    assert_difference('Game.count', 1) do
      post games_url, params: { game: { player1_id: user2.id, player2_id: user3.id } }
    end
    
    assert_nil Game.last.player2_id
  end
  
  test "should not create game with status other than PENDING" do
    user2 = users(:two)
    log_in_as user2
    
    assert_difference('Game.count', 1) do
      post games_url, params: { game: { player1_id: user2.id, status: Game::P1_WON } }
    end
    
    assert_equal Game::PENDING, Game.last.status
  end

  test "should show created game" do
    log_in_as @user
    get game_url(@game)
    assert_response :success
  end
  
  test "should show joined game" do
    log_in_as users(:two)
    get game_url(@game)
    assert_response :success
  end
  
  test "should redirect from show game to login if not logged in" do
    get game_url(@game)
    assert_redirected_to login_path
  end
  
  test "should not show game user is not participating in" do
    log_in_as users(:three)
    get game_url(@game)
    assert_response :forbidden
  end
  
  test "should not replace first player" do
    user3 = users(:three)
    log_in_as user3
    
    patch game_url(@game), params: { game: { player1_id: user3.id } }
    @game.reload
    
    assert_equal @user.id, @game.player1_id
    assert_response :bad_request
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
  
  test "should not replace second player" do
    user3 = users(:three)
    log_in_as user3
    
    patch game_url(@game), params: { game: { player2_id: user3.id } }
    @game.reload
    
    assert_equal users(:two).id, @game.player2_id
    assert_response :forbidden
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
  
  test "should not accept player resignation from user other than player" do
    log_in_as @user
    
    patch game_url(@game), params: { game: { status: Game::P2_FORFEIT } }
    @game.reload
    
    assert_equal Game::PENDING, @game.status
    assert_response :forbidden
  end
  
  test "should not accept player resignation for waiting game" do
    log_in_as @user
    waiting_game = games(:waiting_game)
    
    patch game_url(@game), params: { game: { status: Game::P1_FORFEIT } }
    @game.reload
    
    assert_equal Game::PENDING, @game.status
    assert_response :forbidden
  end
  
  test "should not accept player resignation for completed game" do
    log_in_as users(:two)
    forfeited_game = games(:forfeited_game)
    
    patch game_url(@game), params: { game: { status: Game::P2_FORFEIT } }
    @game.reload
    
    assert_equal Game::P1_FORFEIT, @game.status
    assert_response :forbidden
  end
  
  test "should not allow user to change game status to P1_WON" do
    log_in_as @user
    patch game_url(@game), params: { game: { status: Game::P1_WON } }
    @game.reload
    
    assert_equal Game::PENDING, @game.status
    assert_response :forbidden
  end
  
  test "should not allow user to change game status to P2_WON" do
    log_in_as users(:two)
    patch game_url(@game), params: { game: { status: Game::P2_WON } }
    @game.reload
    
    assert_equal Game::PENDING, @game.status
    assert_response :forbidden
  end
  
  test "should not allow user to change game status to DRAW" do
    log_in_as @user
    patch game_url(@game), params: { game: { status: Game::DRAW } }
    @game.reload
    
    assert_equal Game::PENDING, @game.status
    assert_response :forbidden
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
  
  test "should not destroy game if game has second player" do
    log_in_as @user
    assert_no_difference('Game.count') { delete game_url(@game) }
    assert_response :forbidden
  end
  
  test "should not destroy game if user other than creator is logged in" do
    log_in_as users(:two)
    assert_no_difference('Game.count') { delete game_url(games(:waiting_game)) }
    assert_response :forbidden
  end
end
