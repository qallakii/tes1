require "test_helper"

class ShareLinksControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get share_links_show_url
    assert_response :success
  end

  test "should get create" do
    get share_links_create_url
    assert_response :success
  end
end
