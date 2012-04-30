require 'test_helper'

class SubnetTest < ActiveSupport::TestCase

  test "required subnet values" do
    assert Subnet.create().invalid?, "subnet without mask_bits or base is invalid"
    assert Subnet.create( :base => "10.11.12.0" ).invalid?, "subnet without mask_bits is invalid"
    assert Subnet.create( :mask_bits => 24 ).invalid?, "subnet without a base is invalid"

    assert Subnet.create( :base => "192.168.2.1", :mask_bits => 24 ).valid?, "subnet with all required fields set is valid"
  end

  test "bogus values cause create failures" do 
    assert Subnet.create( :base => 'bogus', :mask_bits => 24 ).invalid?
    assert Subnet.create( :base => '300.11.12.0', :mask_bits => 24 ).invalid?
    assert Subnet.create( :base => '10.11.12.0', :mask_bits => "bogus" ).invalid?, "bogus mask_bits results in invalid object"
    assert Subnet.create( :base => '10.11.12.0', :mask_bits => -1 ).invalid?
    assert Subnet.create( :base => '10.11.12.0', :mask_bits => 33 ).invalid?
    assert Subnet.create( :base => '10.11.12.0', :mask_bits => 293872984572398975 ).invalid?
  end 

  test "base is normalized to network" do
    subnet = Subnet.create( :base => '10.11.12.33', :mask_bits => 24 )
    assert_equal( '10.11.12.0', subnet.base )
  end

  test "does not allow duplicate/overlapping subnets" do
    assert Subnet.create( :base => "10.1.41.0", :mask_bits => 24 ).valid?

    # creating the same subnet fails
    assert Subnet.create( :base => "10.1.41.0", :mask_bits => 24 ).invalid?, "identical base and mask_bits cause failure"

    # this overlaps with the network created above, so it should fail
    assert Subnet.create( :base => "10.1.40.0", :mask_bits => 23 ).invalid?
  end

  test "small subnets succeed" do 
    assert Subnet.create( :base => "10.1.0.0", :mask_bits => 32 ).valid?
    assert Subnet.create( :base => "10.2.0.0", :mask_bits => 31 ).valid?
    assert Subnet.create( :base => "10.3.0.0", :mask_bits => 30 ).valid?
  end 
  
  test "ips are correctly created and destroyed" do
    s = Subnet.create( :base => "12.1.0.0", :mask_bits => 24 )
    assert_equal s.ips.count, 256, "there are 256 ips in a /24 subnet"

    in_use_ips = s.ips.where( :state => "available" ).pluck( :ip )
    assert_equal in_use_ips.length, 256, "all ips in a /24 are available"

    s_id = s.id
    s.destroy
    assert_equal Ip.where( :subnet_id => s_id ).count, 0, "destroying the subnet destroys the ips"
  end
end
