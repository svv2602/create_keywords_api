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

ActiveRecord::Schema[7.1].define(version: 2025_04_10_024128) do
  create_table "addon_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language"
  end

  create_table "addons", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language"
  end

  create_table "brand_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "type_url", default: 0
    t.string "language"
  end

  create_table "brands", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "type_url", default: 0
    t.string "language"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language"
  end

  create_table "city_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language"
  end

  create_table "city_url_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language"
  end

  create_table "city_urls", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language"
  end

  create_table "copy_ready_reviews20s", force: :cascade do |t|
    t.integer "id_review"
    t.text "review_ru"
    t.text "review_ua"
    t.string "control"
    t.integer "characters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "copy_ready_reviews25s", force: :cascade do |t|
    t.integer "id_review"
    t.text "review_ru"
    t.text "review_ua"
    t.string "control"
    t.integer "characters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "copy_ready_reviews30s", force: :cascade do |t|
    t.integer "id_review"
    t.text "review_ru"
    t.text "review_ua"
    t.string "control"
    t.integer "characters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "copy_ready_reviews35s", force: :cascade do |t|
    t.integer "id_review"
    t.text "review_ru"
    t.text "review_ua"
    t.string "control"
    t.integer "characters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "copy_ready_reviews40s", force: :cascade do |t|
    t.integer "id_review"
    t.text "review_ru"
    t.text "review_ua"
    t.string "control"
    t.integer "characters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "copy_ready_reviews45s", force: :cascade do |t|
    t.integer "id_review"
    t.text "review_ru"
    t.text "review_ua"
    t.string "control"
    t.integer "characters"
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

  create_table "questions_blocks", force: :cascade do |t|
    t.integer "type_paragraph", default: 0
    t.integer "type_season", default: 0
    t.string "question_ru", default: ""
    t.string "answer_ru", default: ""
    t.string "question_ua", default: ""
    t.string "answer_ua", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ready_reviews", force: :cascade do |t|
    t.integer "id_review"
    t.text "review_ru"
    t.text "review_ua"
    t.string "control"
    t.integer "characters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ready_reviews_without_params", force: :cascade do |t|
    t.text "review_ru"
    t.text "review_ua"
    t.string "control"
    t.string "gender"
    t.integer "characters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.string "gender"
    t.string "season"
    t.string "type_review"
    t.integer "param1"
    t.integer "param2"
    t.integer "param3"
    t.integer "param4"
    t.integer "param5"
    t.integer "param6"
    t.text "main_string"
    t.text "additional_string"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "season_copies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language"
  end

  create_table "seasons", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language"
  end

  create_table "seo_content_text_sentences", force: :cascade do |t|
    t.string "str_seo_text"
    t.integer "str_number"
    t.string "sentence"
    t.integer "num_snt_in_str"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "id_text"
    t.string "type_text"
    t.integer "check_title", default: 0
    t.string "sentence_ua", default: ""
  end

  create_table "seo_content_texts", force: :cascade do |t|
    t.string "str"
    t.string "content_type"
    t.integer "str_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "type_text"
    t.integer "order_out", default: 0
    t.integer "type_tag"
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

  create_table "test_table_car2_brands", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "translit_ru"
    t.string "translit_ua"
  end

  create_table "test_table_car2_kit_disk_sizes", force: :cascade do |t|
    t.integer "kit"
    t.string "width"
    t.string "diameter"
    t.string "et"
    t.string "type_type"
    t.string "axle"
    t.string "axle_group"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test_table_car2_kits_id"
    t.index ["test_table_car2_kits_id"], name: "idx_on_test_table_car2_kits_id_daa4c566c4"
  end

  create_table "test_table_car2_kit_tyre_sizes", force: :cascade do |t|
    t.integer "kit"
    t.string "width"
    t.string "height"
    t.string "diameter"
    t.string "type_disabled"
    t.string "axle"
    t.string "axle_group"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test_table_car2_kits_id"
    t.index ["test_table_car2_kits_id"], name: "idx_on_test_table_car2_kits_id_a262e6288b"
  end

  create_table "test_table_car2_kits", force: :cascade do |t|
    t.integer "model"
    t.string "year"
    t.string "name"
    t.string "pcd"
    t.string "bolt_count"
    t.string "dia"
    t.string "bolt_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test_table_car2_models_id"
    t.index ["test_table_car2_models_id"], name: "index_test_table_car2_kits_on_test_table_car2_models_id"
  end

  create_table "test_table_car2_models", force: :cascade do |t|
    t.integer "brand"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test_table_car2_brand_id"
    t.string "translit_ru"
    t.string "translit_ua"
    t.index ["test_table_car2_brand_id"], name: "index_test_table_car2_models_on_test_table_car2_brand_id"
  end

  create_table "text_errors", force: :cascade do |t|
    t.string "line"
    t.string "type_line"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "line_ua"
    t.index ["line_ua", "line"], name: "index_text_errors_on_line_ua_and_line", unique: true
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

  add_foreign_key "test_table_car2_kit_disk_sizes", "test_table_car2_kits", column: "test_table_car2_kits_id"
  add_foreign_key "test_table_car2_kit_tyre_sizes", "test_table_car2_kits", column: "test_table_car2_kits_id"
  add_foreign_key "test_table_car2_kits", "test_table_car2_models", column: "test_table_car2_models_id"
  add_foreign_key "test_table_car2_models", "test_table_car2_brands"
end
