class AddVisionApiFieldsToMedia < ActiveRecord::Migration[7.2]
  def change
    add_column :media, :score1, :string
    add_column :media, :score2, :string
    add_column :media, :score3, :string
    add_column :media, :score4, :string
    add_column :media, :score5, :string
    add_column :media, :description1, :string
    add_column :media, :description2, :string
    add_column :media, :description3, :string
    add_column :media, :description4, :string
    add_column :media, :description5, :string
    add_column :media, :bestGuessLabel, :string
  end
end
