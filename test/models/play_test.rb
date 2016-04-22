require 'test_helper'

class PlayTest < ActiveSupport::TestCase
  setup do
    @play = Play.new({ game: games(:new_game), number: 1, x: 1, y: 1 })
  end
  
  test "should save valid play" do
    assert @play.save
  end
  
  test "should not save play with invalid x coordinate" do
    @play.x = nil
    assert_not @play.save
    @play.x = -1
    assert_not @play.save
    @play.x = 3
    assert_not @play.save
    @play.x = 1.5
    assert_not @play.save
    @play.x = "a"
    assert_not @play.save
  end
  
  test "should not save play with invalid y coordinate" do
    @play.y = nil
    assert_not @play.save
    @play.y = -1
    assert_not @play.save
    @play.y = 3
    assert_not @play.save
    @play.y = 1.5
    assert_not @play.save
    @play.y = "a"
    assert_not @play.save
  end
  
  test "should not save play with invalid number" do
    @play.number = nil
    assert_not @play.save
    @play.number = 0
    assert_not @play.save
    @play.number = 10
    assert_not @play.save
    @play.number = 1.5
    assert_not @play.save
    @play.number = "a"
    assert_not @play.save
  end
  
  test "should not save play without an associated game" do
    @play.game = nil
    assert_not @play.save
  end
  
  test "player should be consistent with play number" do
    @play.number = 1
    assert @play.player == 1
    @play.number = 2
    assert @play.player == 2
    @play.number = 3
    assert @play.player == 1
    @play.number = 4
    assert @play.player == 2
  end
end
