class CreateCacasInQueues < ActiveRecord::Migration
  def change
    create_table :cacas_in_queues do |t|
      t.string :adapter
      t.integer :event_id
      t.text :data
      t.boolean :accomplished, default: false

      t.timestamps null: false
    end
  end
end
