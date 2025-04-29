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

ActiveRecord::Schema[7.2].define(version: 2025_04_29_170719) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "media", force: :cascade do |t|
    t.string "name"
    t.string "file_type"
    t.string "aws_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "score1"
    t.string "score2"
    t.string "score3"
    t.string "score4"
    t.string "score5"
    t.string "description1"
    t.string "description2"
    t.string "description3"
    t.string "description4"
    t.string "description5"
    t.string "bestGuessLabel"
  end
end
