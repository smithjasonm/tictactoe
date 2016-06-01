require 'test_helper'

class UserSessionTest < ActiveSupport::TestCase
  def setup
    @session = {}
    @cookies = {}
    
    def @cookies.signed
      self
    end
    
    @user_session = UserSession.new(@session, @cookies)
    @user = users(:one)
  end
  
  test "only users should be logged in" do
    assert_raise TypeError do
      @user_session.log_in "string"
    end
  end

  test "should log user in" do
    @user_session.log_in @user
    assert_equal @user.id, @session[:user_id]
    assert_equal @user.id, @cookies.signed[:user_id]
  end
  
  test "should log user in if different user is logged in" do
    @user_session.log_in users(:two)
    @user_session.log_in @user
    assert_equal @user.id, @session[:user_id]
    assert_equal @user.id, @cookies.signed[:user_id]
  end
  
  test "should log user out" do
    @user_session.log_in @user
    @user_session.log_out
    assert_nil @session[:user_id]
    assert_nil @cookies[:user_id]
  end
  
  test "should get current user" do
    assert_nil @user_session.current_user
    @user_session.log_in @user
    current_user = @user_session.current_user
    assert_equal @user.id, current_user.try(:id)
  end
  
  test "should memoize current user" do
    @user_session.log_in @user
    assert_equal @user, @user_session.current_user
    @user_session.log_out
    @user_session = UserSession.new({ user_id: @user.id }, { user_id: @user.id })
    current_user = @user_session.current_user
    assert_equal current_user, @user_session.current_user
  end
  
  test "should determine whether user is logged in" do
    assert_not @user_session.logged_in?
    @user_session.log_in @user
    assert @user_session.logged_in?
    @user_session.log_out
    assert_not @user_session.logged_in?
  end
end