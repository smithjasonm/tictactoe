require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @new_user = User.new(handle: "handle", email: "email@example.com",
                         password: "password", password_confirmation: "password")
  end
  
  def destroy
    @new_user.destroy
  end
  
  test "should not save user without handle" do
    @new_user.handle = ""
    assert_not @new_user.save
  end
  
  test "should not save user with handle containing invalid characters" do
    @new_user.handle = "abc*defg"
    assert_not @new_user.save
    @new_user.handle = "abc defg"
    assert_not @new_user.save
    @new_user.handle = "abc-defg"
    assert_not @new_user.save
  end
  
  test "should not save user with handle whose intial character is not alphanumeric" do
    @new_user.handle = "_abcdefg"
    assert_not @new_user.save
  end
  
  test "should not save user with handle too short" do
    @new_user.handle = "a" * (Rails.configuration.x.minimum_handle_length - 1)
    assert_not @new_user.save
  end
  
  test "should not save user with handle too long" do
    @new_user.handle = "a" * (Rails.configuration.x.maximum_handle_length + 1)
    assert_not @new_user.save
  end
  
  test "should not save user without email address" do
    @new_user.email = ""
    assert_not @new_user.save
  end
  
  test "should not save user with invalidly formatted email address" do
    @new_user.email = "email@example"
    assert_not @new_user.save
    @new_user.email = "email@example."
    assert_not @new_user.save
    @new_user.email = "@example.com"
    assert_not @new_user.save
    @new_user.email = "example.com"
    assert_not @new_user.save
  end
  
  test "should not save user with email address too long" do
    @new_user.email = "a" * (Rails.configuration.x.maximum_email_address_length - 11) +
                      "@example.com"
    assert_not @new_user.save
  end
  
  test "should save user with valid data" do
    assert @new_user.save
  end
  
  test "user should be able to create a new game" do
    user = users(:one)
    assert_difference "user.created_games.size", 1 do
      user.create_game
    end
  end
  
  test "user should be able to join an existing game" do
    user = users(:two)
    assert_difference "user.joined_games.size", 1 do
      user.join_game games(:waiting_game)
    end
  end
  
  test "user should not be able to join a game user created" do
    user = users(:one)
    game = games(:waiting_game)
    assert_equal user, game.player1
    assert_raise JoiningUserCreatedGameError do
      user.join_game(game)
    end
  end
  
  test "user should not be able to join a game already joined by different user" do
    user = users(:three)
    game = games(:pending_game)
    assert_not_nil game.player2
    assert_not_equal user, game.player2
    assert_raise GameAlreadyJoinedError do
      user.join_game(game)
    end
  end
  
  test "user should be able to resign from a game user created" do
    user = users(:one)
    game = games(:pending_game)
    assert_equal Game::PENDING, game.status
    user.resign_from_game(game)
    assert_equal Game::P1_FORFEIT, game.status
  end
  
  test "user should be able to resign from a game user joined" do
    user = users(:two)
    game = games(:pending_game)
    assert_equal Game::PENDING, game.status
    user.resign_from_game(game)
    assert_equal Game::P2_FORFEIT, game.status
  end
  
  test "user should be able to retrieve user's game record" do
    user = users(:one)
    assert user.game_record.is_a? Hash
    assert user.game_record.has_key?(:wins)
    assert user.game_record.has_key?(:losses)
    assert user.game_record.has_key?(:draws)
  end
end
