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

ActiveRecord::Schema.define(version: 20150804073947) do

  create_table "cacas_in_queues", force: :cascade do |t|
    t.string   "adapter"
    t.integer  "event_id"
    t.text     "data"
    t.boolean  "accomplished", default: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "event"
  end

  create_table "employers", force: :cascade do |t|
    t.string   "name"
    t.integer  "contact_user"
    t.boolean  "is_client"
    t.text     "groups"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "events", force: :cascade do |t|
    t.string   "event"
    t.text     "data"
    t.datetime "created_at"
  end

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.boolean  "every_employee"
    t.integer  "employer_id"
    t.integer  "redmine_id"
    t.text     "users"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "groups", ["employer_id"], name: "index_groups_on_employer_id"

  create_table "jobs", force: :cascade do |t|
    t.string  "adapter_name"
    t.integer "last_even_id"
    t.boolean "solid"
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.integer  "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "projects", ["client_id"], name: "index_projects_on_client_id"

  create_table "users", force: :cascade do |t|
    t.string   "login"
    t.string   "surname"
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.boolean  "is_blocked"
    t.integer  "redmine_id"
    t.string   "redmine_password_hash"
    t.text     "groups"
    t.string   "employer_position"
    t.integer  "employer_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.string   "redmine_login"
    t.string   "redmine_mail"
  end

end
