require 'test_helper'

class NotLoggedInTest < ActionDispatch::IntegrationTest
  test "can see menu links" do
    get "/"
    assert_select "a[href='/']"
    assert_select "a[href='/users/new']"
    assert_select "a[href='/login']"
  end
  
  test "can see home page" do
    get "/"
    assert_response :success
    assert_select "title", /Tic-Tac-Toe/
  end
  
  test "can see sign-up page" do
    get "/users/new"
    assert_response :success
    assert_select "#new_user", 1
  end
  
  test "can see login page" do
    get "/login"
    assert_response :success
    assert_select "form[action='/login']", 1
  end
  
  test "can sign up" do
    get "/users/new"
    post "/users", params: { user: { handle: 'new_user',
                                      email: 'new_user@example.com',
                                   password: 'secret',
                      password_confirmation: 'secret' } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select ".record-list", 1
  end
  
  test "can log in" do
    user = users(:one)
    get "/login"
    post "/login", params: { email: user.email, password: 'secret' }
    assert_redirected_to "/games"
    follow_redirect!
    assert_response :success
  end
  
end
