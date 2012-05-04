class RecordValidator < ActiveModel::Validator
  def validate(record)
    if !record.name_content_type_unique?
      record.errors[:base] << "a record with the same name and content already exists"
    end

    if !record.A_content_is_managed_ip?
      record.errors[:content] << "#{record.content} is not a managed IP resource"
    end
  end
end

class Record < ActiveRecord::Base

  self.inheritance_column = 'type_inheritance'

  belongs_to :domain

  validates :name, :presence => true
  validates :content, :presence => true

  validates :type, :inclusion => { :in => %w(A AAAA CNAME LOC MX NS SOA SPF SRV TXT PTR) }

  validates :ttl, :prio, :numericality => {
    :greater_than_or_equal_to => 0,
    :only_integer => true
  }, :allow_nil => true

  validates_with RecordValidator

  #TODO validate content is an ipv4 when the type is A
  #TODO validate content is an ipv6 when the type is AAAA
  #TODO validate name is a hostname when the type is A or AAAA or CNAME
  #TODO validate content is a hostname when the type is PTR or a CNAME
  #TODO validate that content is unique for all PTR records
  #TODO validate there is only one SOA per domain
  #TODO validate PTR, A, AAAA, MX (?) and CNAME last half name matches domain name
  #TODO don't allow changes to the record if the domain is type SLAVE

  after_initialize :set_domain
  before_create :create_ptr
  before_update :update_ptr
  before_destroy :destroy_ptr

  before_save :set_ip_in_use
  before_destroy :set_ip_available

  after_save :update_soa_serial

  def name_content_type_unique?
    r = Record.where(
      :name    => self.name, 
      :content => self.content,
      :type    => self.type
    )

    if r.count == 0
      return true
    elsif r.count == 1 && r.first.id == self.id
      # if the record that was returned is this record, then we're okay
      return true
    end

    return false
  end

  def A_content_is_managed_ip?
    if self.type != "A"
      return true
    end

    return !Ip.find_by_ip(self.content).nil?
  end

  def set_domain
    if self.domain
      return true # already set
    end

    unless %w(A AAAA MX CNAME TXT PTR).include?(self.type)
      raise "cannot determine domain name for records of type #{self.type}"
    end

    # start with the "biggest" subdomain and work our way backwards until we 
    # find a match.  Note that foo.example.com belongs in the example.com 
    # domain, not foo.example.com (record names and domain names can overlap)
    name_parts = self.name.split('.')
    (1..name_parts.size-1).each do |i|
      candidate = Domain.find_by_name(
        name_parts[i-name_parts.size..-1].join('.')
      )
      if candidate
        Rails.logger.debug("automatically determined domain (#{candidate.name}) for record with name (#{self.name})")
        self.domain = candidate
        self.domain_id = domain.id
        return true
      end
    end

    raise "could not determine domain for record with name (#{name})"
  end

  def create_ptr
    if type == 'A'
      ptr = self.ptr 
      if ptr.new_record?
        ptr.save
      elsif ptr.content != content
          Rails.logger.warn("PTR record for #{name} already exist pointing to #{ptr.content}")
      end
    end
  end

  def update_ptr
    if type == 'A'
      if self.content_changed? || self.name_changed?
        # delete the old one and create a replacement
        self.ptr(self.content_was, self.name_was).destroy
        self.create_ptr
      end
    end
  end

  def destroy_ptr
    if type == 'A'
      ptr = self.ptr
      # the ptr could be pointing to some other record in the scenario where 
      # there are two A records with the same content, but only one PTR
      # valid example:
      # A   => foo.example.com          => 192.168.1.1
      # A   => bar.example.com          => 192.168.1.1
      # PTR => 1.1.168.192.in-addr.arpa => foo.example.com
      # if bar.example.com is deleted we should not delete the ptr record
      if ptr.content == name
        ptr.destroy
      end
    end
  end

  def set_ip_available
    if type != 'A'
      return true
    end

    ip = Ip.find_by_ip(content)
    ip.state = "available"
    ip.save
  end

  def set_ip_in_use
    if type != 'A'
      return true
    end

    ip = Ip.find_by_ip(content)
    if ip.nil?
      raise "cannot create A record for #{name} because #{content} is not a managed IP"
    end

    # TODO what if the type and the content were changed? 
    if self.content_changed?
      old_ip = Ip.find_by_ip(self.content_was)
      if old_ip
        old_ip.state = "available"
        old_ip.save
      end
    end

    ip.state = "in_use"
    ip.save
  end

  def update_soa_serial
    soas_to_update = []
    if self.type == 'A'
      soas_to_update.push( self.ptr.domain.soa )
    end
    
    if self.type != 'SOA'
      soas_to_update.push( self.domain.soa )
    end

    soas_to_update.each do |soa|
      if soa.nil?
        raise "The domain #{domain.name} has no SOA record!"
      end
      # example soa content
      # ns1.example.com. hostmaster.example.com. 2012041806 7200 1800 604800 3600
      soa_parts = soa.content.split(/\s+/)
      # TODO make this understand dates
      soa_parts[2] = soa_parts[2].to_i + 1
      soa.content = soa_parts.join(' ')
      soa.save
    end
  end

  # given an IP address return the matching PTR record.
  # 
  # You shouldn't have two PTR records for one IP
  # however, it's valid to have two A records with the same IP
  # (this is usually the case with round robin load distribution setups)
  # 
  # if the record already exists, it is returned
  # if it does not exist, it is initialized (but not saved) and returned
  def ptr(a_content=self.content, a_name=self.name, a_type=self.type) 
    if a_type != "A"
      raise "Can't get a matching PTR record for a non-A record (record name #{self.name})"
    end

    # example:
    # record with the ip 204.77.168.10 should have a PTR record with the 
    # content of 10.168.77.204.in-addr.arpa in the domain 
    # 168.77.204.in-addr.arpa
    rev_ip = a_content.split('.').reverse
    domain_name = rev_ip[1..3].join('.') + '.in-addr.arpa'
    domain = Domain.find_by_name( domain_name )

    if domain.nil? 
      # XXX this is questionable
      # TODO make type configurable?
      domain = Domain.create!(:name => domain_name, :type => "NATIVE")
      Rails.logger.warn("created in-addr.arpa domain " + domain_name)
    end

    name = rev_ip.join('.') + '.in-addr.arpa'

    ptr = Record.find_or_initialize_by_name_and_type_and_domain_id(
      :name       => name, 
      :type       => 'PTR',
      :domain_id  => domain.id
    )

    # only set the name if we initialized a new record rather than 
    # found an existing one
    # this allows us to avoid having two PTR records pointing to the same IP
    if ptr.new_record?
      ptr.content = a_name
    end

    return ptr
  end
end
