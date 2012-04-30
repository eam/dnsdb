class CreatePdns < ActiveRecord::Migration

  def up
    create_table "domains", :force => true do |t|
      t.string  "name",                           :null => false
      t.string  "master",          :limit => 128
      t.integer "last_check"
      t.string  "type",            :limit => 6,   :null => false
      t.integer "notified_serial"
      t.string  "account",         :limit => 40
    end

    add_index "domains", ["name"], :name => "name_index", :unique => true

    create_table "records", :force => true do |t|
      t.integer "domain_id"
      t.string  "name"
      t.string  "type",        :limit => 10
      t.text    "content",     :limit => 64000
      t.integer "ttl"
      t.integer "prio"
      t.integer "change_date"
    end

    add_index "records", ["domain_id"], :name => "domain_id"
    add_index "records", ["name", "type"], :name => "nametype_index"
    add_index "records", ["name"], :name => "rec_name_index"

    create_table "supermasters", :id => false, :force => true do |t|
      t.string "ip",         :limit => 25, :null => false
      t.string "nameserver",               :null => false
      t.string "account",    :limit => 40
    end
  end

  def down
    raise
  end
end
