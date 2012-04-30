class Ip < ActiveRecord::Base
  belongs_to :subnet

  validates :subnet_id, :presence => true
  validates :ip, :presence => true, :ip => { :format => :v4 }, :uniqueness => true
  validates :state, :inclusion => { :in => %w( in_use available ) }
end
