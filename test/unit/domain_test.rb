require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  test "creating a domain automatically creates the SOA record" do
    # confirm it doesn't exist 
    assert_nil Record.where( :type => "SOA", :name => "zone.bogus.example.com" ).first

    # creating a domain should create the SOA record
    assert_not_nil Domain.create( 
      :name => "zone.bogus.example.com",
      :type => "NATIVE"
    )
    
    # confirm SOA record got created
    assert_not_nil Record.where( :type => "SOA", :name => "zone.bogus.example.com" ).first
  end

  test "creating a SLAVE domain should NOT create the SOA record" do
    # confirm it doesn't exist 
    assert_nil Record.where( :type => "SOA", :name => "zone.bogus.example.com" ).first

    # creating a domain should create the SOA record
    assert_not_nil Domain.create( 
      :name => "zone.bogus.example.com",
      :type => "SLAVE"
    )
    
    # confirm SOA record still doesn't exist
    assert_nil Record.where( :type => "SOA", :name => "zone.bogus.example.com" ).first
  end
end
