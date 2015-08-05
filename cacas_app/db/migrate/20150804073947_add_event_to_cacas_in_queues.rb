class AddEventToCacasInQueues < ActiveRecord::Migration
  def change
    add_column :cacas_in_queues, :event, :string
  end
end
