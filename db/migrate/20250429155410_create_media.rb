class CreateMedia < ActiveRecord::Migration[7.2]
  def change
    create_table :media do |t|
      t.string :name
      t.string :file_type
      t.string :aws_url

      t.timestamps
    end
  end
end
