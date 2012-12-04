require 'netaddr'

class SubnetValidator < ActiveModel::Validator
  def validate(subnet)
    # validate that this subnet doesn't already exist
    # note that this subnet could be part of a larger subnet so we'll need to
    # see if any IPs in the new subnet already exist in any other subnet
    begin 
      cidr = NetAddr::CIDR.create( "#{subnet.base}/#{subnet.mask_bits}" )
    rescue
      # NetAddr::CIDR will throw when invalid data is passed to new
      # assume that the other validators will catch these errors
      return
    end

    if subnet.new_record?
      existing_ip = Ip.find_by_ip( cidr.enumerate )
      if !existing_ip.nil?
        subnet.errors[:base] << "at least part of subnet #{subnet.base}/#{subnet.mask_bits} already exists in subnet #{existing_ip.subnet_id}"
      end
    end
  end
end

class Subnet < ActiveRecord::Base
  has_many :ips, :dependent => :destroy

  validates :base, :presence => true, :uniqueness => true, :ip => { :format => :v4 }
  validates :mask_bits, :presence => true, 
                        :numericality => { 
                            :only_integer => true, 
                            # anything larger than a /12 and expanding it takes too long
                            :greater_than_or_equal_to => 12,
                            :less_than_or_equal_to => 32 
                        }
  validates_with SubnetValidator

  # normalize base.  e.g. 10.1.1.33/24 => 10.1.1.0/24
  before_save do |subnet|
    subnet.base = subnet.cidr.network
  end

  # create all the IPs for this subnet (:dependent will destroy them for us)
  after_create do |subnet|
    cidr = subnet.cidr
    cidr.enumerate.each do |ip|
      Ip.create!( :ip => ip, :state => "available", :subnet => subnet )
    end

    # set base, broadcast and gateway IP's to 'in_use'
    Ip.find_by_ip(cidr.nth(0)) { |ip| ip.state = "in_use" }
    if cidr.size > 1
      Ip.find_by_ip(cidr.nth(1)) { |ip| ip.state = "in_use" }
      Ip.find_by_ip(cidr.last)   { |ip| ip.state = "in_use" }
    end
  end
 
  # don't allow updates, only create, read and destroy
  # this is because updating will invalidate all the children IPs
  before_update do |subnet|
    raise ActiveRecordError
  end

  protected 
  def cidr 
    NetAddr::CIDR.create( "#{self.base}/#{self.mask_bits}" )
  end 
end
