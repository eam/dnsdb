require 'date'

class Domain < ActiveRecord::Base

  self.inheritance_column = 'type_inheritance'

  has_many :records, :dependent => :destroy

  validates :name, :presence => true, :uniqueness => true
  validates :master, :ip => { :format => :v4 }, :allow_nil => true
  validates :type, :inclusion => { :in => %w(NATIVE MASTER SLAVE) }

  after_create :create_soa

  # return the soa record that is associated with this domain
  def soa
    Record.where( :domain_id => self.id, :type => 'SOA' ).first
  end

  def create_soa 
    if self.type == "SLAVE" 
      return
    end

    serial = Date.today.strftime("%Y%m%d00") 
    Record.create( 
      :domain_id => self.id,
      :type      => 'SOA',
      :name      => self.name,
      # format:
      # mname rname serial refresh retry expire minimum
      # example:
      # ns.example.com. hostmaster.example.com. 2012041806 7200 1800 604800 3600
      # TODO make these values configurable
      :content   => "ns.example.com. hostmaster.example.com. #{serial} 7200 1800 604800 3600"
    )
  end
end
