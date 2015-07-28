class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :adapter_name
      t.integer :last_even_id
      t.boolean :solid
    end
  end
end
