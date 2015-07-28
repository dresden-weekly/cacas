class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :event_name
      t.integer :last_id
      t.boolean :solid
    end
  end
end
