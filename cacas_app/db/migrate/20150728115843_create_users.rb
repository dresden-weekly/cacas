class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :login
      t.string :surname
      t.string :name
      t.string :email
      t.string :phone
      t.boolean :is_blocked, default: false
      t.integer :redmine_id
      t.string :redmine_password_hash
      t.text :groups
      t.string :employer_position
      t.references :employer

      t.timestamps null: false
    end
  end
end
