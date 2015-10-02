class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users, id: :uuid do |t|
      # t.uuid :id, :primary_key => true, null: false
      t.string :name

      t.timestamps null: false
    end
  end
end
