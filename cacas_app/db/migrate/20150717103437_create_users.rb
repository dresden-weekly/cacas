class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      # sequential UUID as primary key in Postgres:
      # t.primary_key :id, :uuid, :default => 'uuid_generate_v1()'
      # or as additional regular field (not sequential - Postgres only as well):
      # t.uuid :uuid
      t.string :username
      t.string :firstname
      t.string :lastname
      t.string :email

      t.timestamps null: false
    end
  end
end
