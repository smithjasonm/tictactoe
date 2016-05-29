require 'test_helper'

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url
    assert_response :success
  end
  
  test "should redirect from home to games if logged in" do
    log_in_as users(:one)
    get root_url
    assert_redirected_to games_path
  end
  
end
