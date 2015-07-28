class CreateEmployers < ActiveRecord::Migration
  def change
    create_table :employers do |t|
      t.string :name
      t.integer :contact_user
      t.boolean :is_client
      t.text :groups

      t.timestamps null: false
    end
  end
end
