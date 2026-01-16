# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_15_124000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cvs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "filename"
    t.bigint "folder_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["folder_id"], name: "index_cvs_on_folder_id"
    t.index ["user_id"], name: "index_cvs_on_user_id"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "ratings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "cv_id", null: false
    t.integer "stars"
    t.datetime "updated_at", null: false
    t.index ["cv_id"], name: "index_ratings_on_cv_id"
  end

  create_table "share_link_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "share_link_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["share_link_id", "user_id"], name: "index_share_link_accesses_on_share_link_id_and_user_id", unique: true
    t.index ["share_link_id"], name: "index_share_link_accesses_on_share_link_id"
    t.index ["user_id"], name: "index_share_link_accesses_on_user_id"
  end

  create_table "share_link_cvs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "cv_id", null: false
    t.bigint "share_link_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cv_id"], name: "index_share_link_cvs_on_cv_id"
    t.index ["share_link_id", "cv_id"], name: "index_share_link_cvs_on_share_link_id_and_cv_id", unique: true
    t.index ["share_link_id"], name: "index_share_link_cvs_on_share_link_id"
  end

  create_table "share_link_folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "folder_id", null: false
    t.bigint "share_link_id", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_id"], name: "index_share_link_folders_on_folder_id"
    t.index ["share_link_id", "folder_id"], name: "index_share_link_folders_on_share_link_id_and_folder_id", unique: true
    t.index ["share_link_id"], name: "index_share_link_folders_on_share_link_id"
  end

  create_table "share_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "folder_id"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["folder_id"], name: "index_share_links_on_folder_id"
    t.index ["token"], name: "index_share_links_on_token", unique: true
    t.index ["user_id"], name: "index_share_links_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "password_digest"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cvs", "folders"
  add_foreign_key "cvs", "users"
  add_foreign_key "folders", "folders", column: "parent_id"
  add_foreign_key "folders", "users"
  add_foreign_key "ratings", "cvs"
  add_foreign_key "share_link_accesses", "share_links"
  add_foreign_key "share_link_accesses", "users"
  add_foreign_key "share_link_cvs", "cvs"
  add_foreign_key "share_link_cvs", "share_links"
  add_foreign_key "share_link_folders", "folders"
  add_foreign_key "share_link_folders", "share_links"
  add_foreign_key "share_links", "folders"
  add_foreign_key "share_links", "users"
end
