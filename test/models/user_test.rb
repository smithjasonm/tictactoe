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
end
