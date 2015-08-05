class JobQueue < ActiveRecord::Base
  self.table_name = :cacas_in_queues

  serialize :data, JSON #, symbolize_names: true

  # def self.create adapter, fields
  #   self.create! adapter: adapter
  # end
  def self.accomplished? job
    where(event_id: job.event_id, adapter: job.adapter, accomplished: true).size > 0
  end

  def self.create_or_update atts
    existing = where(adapter: atts[:adapter], event_id: atts[:event_id]).first
    if existing
      existing.update atts
    else
      create atts
    end
  end
end
