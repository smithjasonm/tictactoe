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
  
  test "handle should be unique (without regard to case)" do
    @new_user.handle = "user1"
    assert @new_user.invalid?
  end
  
  test "handle should be trimmed before saving" do
    @new_user.handle = "  handle"
    @new_user.save!
    assert_equal "handle", @new_user.handle
    @new_user.handle = "handle2  "
    @new_user.save!
    assert_equal "handle2", @new_user.handle
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
  
  test "email should be unique (without regard to case)" do
    @new_user.email = "User1@example.com"
    assert @new_user.invalid?
  end
  
  test "email should be trimmed before saving" do
    @new_user.email = "  email@example.com"
    @new_user.save!
    assert_equal "email@example.com", @new_user.email
    @new_user.email = "email2@example.com  "
    @new_user.save!
    assert_equal "email2@example.com", @new_user.email
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
  
  test "should get all games" do
    user = users(:two)
    expected = [games(:pending_game).id, games(:new_game).id, games(:forfeited_game).id]
    all_games = user.all_games
    assert_equal 3, all_games.size
    all_games.each { |game| assert_includes expected, game.id }
  end
  
  test "should get ongoing games" do
    user = users(:one)
    expected = [games(:pending_game).id, games(:new_game).id]
    ongoing_games = user.ongoing_games
    assert_equal 2, ongoing_games.size
    ongoing_games.each { |game| assert_includes expected, game.id }
  end
  
  test "should get completed games" do
    user = users(:one)
    expected = games(:forfeited_game)
    completed_games = user.completed_games
    assert_equal 1, completed_games.size
    assert_equal expected.id, completed_games[0].id
  end
  
  test "should get completed games with limit specified" do
    user = users(:one)
    assert_equal 0, user.completed_games(0).size
    assert_equal 1, user.completed_games(1).size
    assert_equal 1, user.completed_games(2).size # user :one only has one completed game
  end
  
  test "should get waiting game if present" do
    assert users(:one).waiting_game.try('waiting?')
    assert_nil users(:two).waiting_game
  end
end
