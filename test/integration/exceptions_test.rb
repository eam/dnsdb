require 'test_helper'

class ExceptionsTest < ActionController::IntegrationTest
  fixtures :all
  def setup
    RecordsController.any_instance.stubs(:index) { raise "bogus error" }
  end

  test "user gets a 500 json error when the application raises" do
    get "/records", nil, {'HTTP_ACCEPT' => 'application/json'}
    assert_response :error
  end
end
