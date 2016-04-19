require 'test_helper'

class PlayTest < ActiveSupport::TestCase
  setup do
    @play = plays(:pending_game_play_1)
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
  
  test "should not save play with invalid player number" do
    @play.player = nil
    assert_not @play.save
    @play.player = 0
    assert_not @play.save
    @play.player = 3
    assert_not @play.save
    @play.player = 1.5
    assert_not @play.save
    @play.player = "a"
    assert_not @play.save
  end
  
  test "should not save play without an associated game" do
    @play.game = nil
    assert_not @play.save
  end
end
