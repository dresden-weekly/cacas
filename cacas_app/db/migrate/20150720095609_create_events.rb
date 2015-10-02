class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :event
      t.text :data
      t.text :refchain
      t.integer :cut_refchain_at
      t.datetime :created_at
    end
  end
end
