class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.boolean :every_employee
      t.references :employer, index: true, foreign_key: true
      t.integer :redmine_id
      t.text :users

      t.timestamps null: false
    end
  end
end
