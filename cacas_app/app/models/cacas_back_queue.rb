class CacasBackQueue < ActiveRecord::Base
  establish_connection "cacas_#{Rails.env}".to_sym
  self.table_name = :queue

  serialize :data, JSON

  def self.accomplished? job
    where(event_id: job.event_id, adapter: job.adapter, accomplished: true).size > 0
  end

  def self.get_matching job
    where(event_id: job.event_id, adapter: job.adapter).first
  end
end
