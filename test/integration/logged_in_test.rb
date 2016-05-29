require 'test_helper'

class LoggedInTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    log_in_as @user
  end
  
  test "can see menu links" do
    get "/games"
    assert_select "a[href='/games']"
    assert_select "a[href='/users']"
    assert_select "a[href='/users/#{@user.id}']"
    assert_select "a[href='/users/#{@user.id}/edit']"
    assert_select "a[href='/logout']"
  end
  
  test "can see the games page" do
    get "/games"
    assert_response :success
    
    assert_select "title", /Games/
    assert_select_game games(:pending_game)
    assert_select_game games(:new_game)
    assert_select ".user-waiting-game", 1
    assert_select ".completed-game", 1
    assert_select "#new_game", 0
  end
  
  test "can create a game" do
    user2 = users(:two)
    log_in_as user2
    
    get "/games"
    assert_select "#new_game", 1
    post "/games", params: { game: { player1_id: user2.id } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select ".game", 1
  end
  
  test "can join a game" do
    user2 = users(:two)
    game = games(:waiting_game)
    log_in_as user2
    
    get "/games"
    assert_select "#edit_game_#{game.id}", 1
    patch "/games/#{game.id}", params: { game: { player2_id: user2.id } }
    assert_redirected_to "/games/#{game.id}"
    follow_redirect!
    assert_response :success
    assert_select_game game
  end
  
  test "can visit an ongoing game" do
    visit_game games(:pending_game)
    assert_select ".record-list", 1
  end
  
  test "can visit a completed game" do
    visit_game games(:forfeited_game)
    assert_select ".record-list", 1
  end
  
  test "can visit own waiting game" do
    visit_game games(:waiting_game)
    assert_select ".record-list", 0
  end
  
  test "can quit own waiting game" do
    game = games(:waiting_game)
    visit_game game
    assert_select ".edit_game", 1
    delete "/games/#{game.id}"
    assert_redirected_to "/games"
    follow_redirect!
    assert_response :success
    assert_select ".user-waiting-game", 0
  end
  
  test "can resign from game" do
    game = games(:pending_game)
    visit_game game
    assert_select ".edit_game", 1
    patch "/games/#{game.id}", params: { game: { status: Game::P1_FORFEIT } }
    assert_redirected_to "/games/#{game.id}"
    follow_redirect!
    assert_response :success
    assert_select ".game[data-status='#{Game::P1_FORFEIT}']"
  end
  
  test "can see own profile" do
    get "/users/#{@user.id}"
    assert_response :success
    assert_select ".avatar", 2
    assert_select ".record-list", 1
  end
  
  test "can see other user's profile" do
    user2 = users(:two)
    get "/users/#{user2.id}"
    assert_response :success
    assert_select ".avatar", 2
    assert_select ".record-list", 2
  end
  
  test "can see settings" do
    get "/users/#{@user.id}/edit"
    assert_response :success
    assert_select ".avatar", 2
    assert_select "#edit_user_#{@user.id}", 1
  end
  
  test "can update settings" do
    get "/users/#{@user.id}/edit"
    patch "/users/#{@user.id}", params: { user: { handle: @user.handle + '_new' } }
    assert_redirected_to "/users/#{@user.id}"
    follow_redirect!
    assert_response :success
    assert_select ".alert-success"
  end
  
  test "can log out" do
    get "/games"
    delete "/logout"
    assert_redirected_to "/"
    follow_redirect!
    assert_response :success
  end
  
  private
    
    def assert_select_game(game)
      assert_select ".game[data-id='#{game.id}']", 1
    end
    
    def visit_game(game)
      get "/games"
      assert_select "a[href='/games/#{game.id}']", 1
      get "/games/#{game.id}"
      assert_response :success
      assert_select_game game
    end
end
