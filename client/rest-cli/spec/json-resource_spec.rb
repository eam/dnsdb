$VERBOSE = nil # suppress warnings
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'json-resource'
require 'describe_internally'

describe_internally RestClient::Resource::Json do
  describe "parse" do
    it "should return nil when content is unparsable" do
      rsrc = RestClient::Resource::Json.new "http://example.com"
      rsrc.parse(" ").should eq nil
      rsrc.parse("abc").should eq nil
    end
  end
end
