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

ActiveRecord::Schema[7.1].define(version: 2024_03_04_100342) do
  create_table "addon_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "addons", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "brand_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "brands", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "city_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "city_url_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "city_urls", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "diameter_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "diameters", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "diski_faq_copies", force: :cascade do |t|
    t.string "question"
    t.string "theme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "diski_faqs", force: :cascade do |t|
    t.string "question"
    t.string "theme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "season_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "seasons", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "size_copies", force: :cascade do |t|
    t.string "ww"
    t.string "hh"
    t.string "rr"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sizes", force: :cascade do |t|
    t.string "ww"
    t.string "hh"
    t.string "rr"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "track_tyres_faq_copies", force: :cascade do |t|
    t.string "question"
    t.string "theme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "track_tyres_faqs", force: :cascade do |t|
    t.string "question"
    t.string "theme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tyres_faq_copies", force: :cascade do |t|
    t.string "question"
    t.string "theme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tyres_faqs", force: :cascade do |t|
    t.string "question"
    t.string "theme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
