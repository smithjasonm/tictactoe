require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get login_url
    assert_response :success
  end
  
  test "should redirect from new to games if logged in" do
    log_in_as users(:one)
    get login_url
    assert_redirected_to games_path
  end
  
  test "should create session" do
    user = users(:one)
    log_in_as user
    assert_equal user.id, session[:user_id]
    assert_equal user.id, @request.cookie_jar.signed[:user_id]
    assert_redirected_to games_path
  end
  
  test "should redirect from create session to games if logged in" do
    user = users(:one)
    log_in_as user
    log_in_as user
    assert_equal user.id, session[:user_id]
    assert_equal user.id, @request.cookie_jar.signed[:user_id]
    assert_redirected_to games_path
  end
  
  test "should create session if different user is logged in" do
    user = users(:one)
    log_in_as users(:two)
    log_in_as user
    assert_equal user.id, session[:user_id]
    assert_equal user.id, @request.cookie_jar.signed[:user_id]
    assert_redirected_to games_path
  end
  
  test "should not create session with invalid email address" do
    post login_url, params: { email: 'invalid@example.com', password: 'secret' }
    assert_nil session[:user_id]
    assert_nil cookies[:user_id]
    assert_equal login_path, @request.path
  end
  
  test "should not create session with invalid password" do
    post login_url, params: { email: users(:one).email, password: 'invalid' }
    assert_nil session[:user_id]
    assert_nil cookies[:user_id]
    assert_equal login_path, @request.path
  end
  
  test "should destroy session" do
    log_in_as users(:one)
    delete logout_url
    assert_nil session[:user_id]
    assert_nil cookies[:user_id]
    assert_redirected_to root_path
  end
  
  test "should redirect from destroy session to home if not logged in" do
    delete logout_url
    assert_redirected_to root_path
  end
end
