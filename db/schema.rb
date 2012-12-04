# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2) do

  create_table "domains", :force => true do |t|
    t.string  "name",                           :null => false
    t.string  "master",          :limit => 128
    t.integer "last_check"
    t.string  "type",            :limit => 6,   :null => false
    t.integer "notified_serial"
    t.string  "account",         :limit => 40
  end

  add_index "domains", ["name"], :name => "name_index", :unique => true

  create_table "ips", :force => true do |t|
    t.integer  "subnet_id"
    t.string   "ip"
    t.string   "state",      :default => "available"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

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

  create_table "subnets", :force => true do |t|
    t.string   "base"
    t.string   "mask_bits"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "supermasters", :id => false, :force => true do |t|
    t.string "ip",         :limit => 25, :null => false
    t.string "nameserver",               :null => false
    t.string "account",    :limit => 40
  end

end
