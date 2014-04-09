# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140408223215) do

  create_table "changelogs", force: true do |t|
    t.datetime "datetime"
    t.integer  "cpw_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_type_tables", force: true do |t|
  end

  create_table "events", force: true do |t|
    t.string   "title"
    t.datetime "from"
    t.datetime "to"
    t.string   "location"
    t.text     "summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cpw_id"
  end

  create_table "events_types", id: false, force: true do |t|
    t.integer "event_id"
    t.integer "type_id"
  end

  add_index "events_types", ["event_id", "type_id"], name: "index_events_types_on_event_id_and_type_id"
  add_index "events_types", ["type_id"], name: "index_events_types_on_type_id"

  create_table "events_types_tables", force: true do |t|
  end

  create_table "types", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
