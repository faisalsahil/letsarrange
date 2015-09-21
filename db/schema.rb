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

ActiveRecord::Schema.define(version: 20140716215214) do

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "broadcasts", force: true do |t|
    t.integer  "broadcastable_id"
    t.integer  "organization_user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "broadcastable_type"
  end

  add_index "broadcasts", ["broadcastable_id"], name: "index_broadcasts_on_broadcastable_id", using: :btree
  add_index "broadcasts", ["broadcastable_type"], name: "index_broadcasts_on_broadcastable_type", using: :btree
  add_index "broadcasts", ["organization_user_id"], name: "index_broadcasts_on_organization_user_id", using: :btree

  create_table "contact_points", force: true do |t|
    t.string   "type"
    t.integer  "user_id"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "outgoing_caller_sid"
    t.integer  "status",                default: 0
    t.datetime "last_sms_sent_at"
    t.boolean  "notifications_enabled"
  end

  add_index "contact_points", ["confirmation_token"], name: "index_contact_points_on_confirmation_token", unique: true, using: :btree
  add_index "contact_points", ["outgoing_caller_sid"], name: "index_contact_points_on_outgoing_caller_sid", using: :btree
  add_index "contact_points", ["user_id", "type"], name: "index_contact_points_on_user_id_and_type", using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "email_messages", force: true do |t|
    t.integer  "broadcast_id"
    t.string   "uid"
    t.string   "to"
    t.string   "from"
    t.text     "body"
    t.string   "subject"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_messages", ["broadcast_id"], name: "index_email_messages_on_broadcast_id", using: :btree
  add_index "email_messages", ["uid"], name: "index_email_messages_on_uid", using: :btree

  create_table "inbound_numbers", force: true do |t|
    t.string  "number"
    t.integer "request_id"
  end

  add_index "inbound_numbers", ["number"], name: "index_inbound_numbers_on_number", using: :btree

  create_table "line_items", force: true do |t|
    t.integer  "request_id"
    t.integer  "organization_resource_id"
    t.string   "description"
    t.string   "location"
    t.datetime "ideal_start"
    t.datetime "earliest_start"
    t.datetime "finish_by"
    t.string   "length"
    t.integer  "last_edited_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                   default: 0
    t.string   "offer"
    t.integer  "created_for_id"
  end

  add_index "line_items", ["created_for_id"], name: "index_line_items_on_created_for_id", using: :btree
  add_index "line_items", ["last_edited_id"], name: "index_line_items_on_last_edited_id", using: :btree
  add_index "line_items", ["request_id"], name: "index_line_items_on_request_id", using: :btree

  create_table "mappings", force: true do |t|
    t.integer  "user_id"
    t.integer  "endpoint_id"
    t.integer  "entity_id"
    t.string   "entity_type"
    t.string   "code"
    t.integer  "status",      default: 0
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mappings", ["code"], name: "index_mappings_on_code", using: :btree
  add_index "mappings", ["endpoint_id"], name: "index_mappings_on_endpoint_id", using: :btree
  add_index "mappings", ["entity_id"], name: "index_mappings_on_entity_id", using: :btree
  add_index "mappings", ["user_id"], name: "index_mappings_on_user_id", using: :btree

  create_table "organization_resources", force: true do |t|
    t.integer  "organization_id"
    t.integer  "resource_id"
    t.string   "name"
    t.string   "visibility",      default: "public"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "organization_resources", ["organization_id", "resource_id"], name: "index_organization_resources_on_organization_id_and_resource_id", using: :btree
  add_index "organization_resources", ["resource_id", "organization_id"], name: "index_organization_resources_on_resource_id_and_organization_id", using: :btree

  create_table "organization_users", force: true do |t|
    t.integer  "organization_id"
    t.integer  "user_id"
    t.string   "name"
    t.string   "visibility",      default: "public"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",          default: 0
  end

  add_index "organization_users", ["organization_id", "user_id"], name: "index_organization_users_on_organization_id_and_user_id", using: :btree
  add_index "organization_users", ["user_id", "organization_id"], name: "index_organization_users_on_user_id_and_organization_id", using: :btree

  create_table "organizations", force: true do |t|
    t.string   "name"
    t.string   "uniqueid"
    t.string   "visibility",      default: "private"
    t.integer  "default_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "organizations", ["uniqueid"], name: "index_organizations_on_uniqueid", using: :btree

  create_table "requests", force: true do |t|
    t.string   "description"
    t.string   "location"
    t.datetime "ideal_start"
    t.datetime "earliest_start"
    t.datetime "finish_by"
    t.string   "time_zone",                default: "UTC"
    t.string   "length"
    t.integer  "last_edited_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                   default: 0
    t.string   "offer"
    t.integer  "organization_resource_id"
    t.integer  "contact_point_id"
    t.integer  "message_branding",         default: 0
    t.integer  "reserved_number_id"
    t.integer  "created_by_id"
    t.boolean  "suppress_initial_message", default: false
  end

  add_index "requests", ["last_edited_id"], name: "index_requests_on_last_edited_id", using: :btree
  add_index "requests", ["organization_resource_id"], name: "index_requests_on_organization_resource_id", using: :btree
  add_index "requests", ["reserved_number_id"], name: "index_requests_on_reserved_number_id", using: :btree

  create_table "resources", force: true do |t|
    t.string   "name"
    t.string   "uniqueid"
    t.string   "visibility", default: "public"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resources", ["uniqueid"], name: "index_resources_on_uniqueid", using: :btree

  create_table "sms_messages", force: true do |t|
    t.string   "sid"
    t.datetime "date_sent"
    t.string   "to"
    t.string   "from"
    t.text     "body"
    t.string   "status"
    t.string   "uri"
    t.integer  "broadcast_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sms_messages", ["broadcast_id"], name: "index_sms_messages_on_broadcast_id", using: :btree
  add_index "sms_messages", ["to"], name: "index_sms_messages_on_to", using: :btree

  create_table "twilio_numbers", force: true do |t|
    t.string  "number"
    t.integer "status", default: 0
  end

  add_index "twilio_numbers", ["number"], name: "index_twilio_numbers_on_number", using: :btree

  create_table "url_mappings", force: true do |t|
    t.integer "contact_point_id"
    t.string  "code"
    t.string  "path"
    t.integer "status",           default: 0
  end

  add_index "url_mappings", ["code"], name: "index_url_mappings_on_code", using: :btree
  add_index "url_mappings", ["contact_point_id"], name: "index_url_mappings_on_contact_point_id", using: :btree

  create_table "users", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                            default: ""
    t.string   "encrypted_password",               default: "",       null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                    default: 0,        null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",                  default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "name"
    t.string   "uniqueid"
    t.string   "website"
    t.boolean  "admin",                            default: false
    t.string   "visibility",                       default: "public"
    t.integer  "sms_sent_to_user_state",           default: 0
    t.integer  "sms_received_from_user_state",     default: 0
    t.integer  "voice_reset_contact_id"
    t.string   "voice_reset_code"
    t.integer  "default_organization_resource_id"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["default_organization_resource_id"], name: "index_users_on_default_organization_resource_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["name"], name: "index_users_on_name", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uniqueid"], name: "index_users_on_uniqueid", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

end
