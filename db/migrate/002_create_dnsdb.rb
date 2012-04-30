class CreateDnsdb < ActiveRecord::Migration

  def change
    create_table :subnets do |t|
      t.string :base
      t.string :mask_bits 

      t.timestamps
    end

    create_table :ips do |t|
      t.integer :subnet_id
      t.string :ip
      t.string :state, :default => "available"

      t.timestamps
    end
  end
end
