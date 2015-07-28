class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :event
      t.text :data
      t.datetime :created_at
    end
  end
end
