class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects, id: :uuid do |t|
      # t.uuid :id, :primary_key => true, null: false
      t.uuid :user_id
      t.string :name

      t.timestamps null: false
    end
  end
end
