require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get index if logged in" do
    log_in_as @user
    get users_url
    assert_response :success
  end
  
  test "should be redirected from index to login path if logged out" do
    get users_url
    assert_redirected_to login_path
  end

  test "should get new if logged out" do
    get new_user_url
    assert_response :success
  end
  
  test "should be redirected from new to games path if logged in" do
    log_in_as @user
    get new_user_url
    assert_redirected_to games_path
  end

  test "should create user" do
    assert_difference('User.count') { create_user }
    assert_redirected_to user_path(User.last)
  end
  
  test "should render errors creating user" do
    post users_path, params: { user: { email: "bademail",
                                      handle: "invalid_user",
                                    password: 'secret',
                       password_confirmation: 'secret' } }
    
    assert_equal users_path, @request.path
    assert_select ".has-error"
  end
  
  test "should log in after creating user" do
    create_user
    user_id = User.last.id
    assert_equal user_id, session[:user_id]
    assert_equal user_id, @request.cookie_jar.signed[:user_id]
  end

  test "should show self if logged in" do
    log_in_as @user
    get user_url(@user)
    assert_response :success
  end
  
  test "should show other user if logged in" do
    log_in_as @user
    get user_url(users(:two))
    assert_response :success
  end
  
  test "should be redirected from show user to login path if logged out" do
    get user_url(@user)
    assert_redirected_to login_path
  end

  test "should get edit for self if logged in" do
    log_in_as @user
    get edit_user_url(@user)
    assert_response :success
  end
  
  test "should not get edit for other user if logged in" do
    log_in_as @user
    get edit_user_url(users(:two))
    assert_response :forbidden
  end
  
  test "should be redirected from edit to login path if logged out" do
    get edit_user_url(@user)
    assert_redirected_to login_path
  end

  test "should update self if logged in" do
    log_in_as @user
    patch user_url(@user), params: { user: { email: @user.email,
                                            handle: @user.handle,
                                          password: 'secret',
                             password_confirmation: 'secret' } }
    assert_redirected_to user_path(@user)
  end
  
  test "should render errors updating user" do
    log_in_as @user
    patch user_url(@user), params: { user: { password: 'password',
                                password_confirmation: 'password-mismatch' } }
    
    assert_equal user_path(@user), @request.path
    assert_select ".has-error"
  end
  
  test "should not update other user if logged in" do
    log_in_as @user
    user2 = users(:two)
    patch user_url(user2), params: { user: { email: user2.email,
                                            handle: user2.handle,
                                          password: 'secret',
                             password_confirmation: 'secret' } }
    assert_response :forbidden
  end
  
  test "should be redirected from update user to login path if logged out" do
    patch user_url(@user), params: { user: { email: @user.email,
                                            handle: @user.handle,
                                          password: 'secret',
                             password_confirmation: 'secret' } }
    assert_redirected_to login_path
  end

  test "should destroy self if logged in" do
    log_in_as @user
    assert_difference('User.count', -1) { delete user_url(@user) }
    assert_redirected_to root_path
  end
  
  test "should log out after destroy" do
    log_in_as @user
    delete user_url(@user)
    assert_nil session[:user_id]
    assert_nil cookies[:user_id]
  end
  
  test "should not destroy other user if logged in" do
    log_in_as @user
    assert_no_difference('User.count') { delete user_url(users(:two)) }
    assert_response :forbidden
  end
  
  test "should be redirected from destroy user to login path if logged out" do
    assert_no_difference('User.count') { delete user_url(@user) }
    assert_redirected_to login_path
  end
  
  private
  
    def create_user
      post users_path, params: { user: { email: "newuser@example.com",
                                        handle: "newuser",
                                      password: 'secret',
                         password_confirmation: 'secret' } }
    end
  
end