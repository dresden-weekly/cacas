require 'active_record'
require 'active_support/inflector'
require 'json'
require 'pathname'
require_relative 'cacas.rb'
require_relative 'configs.rb'
require_relative 'adapter.rb'


class Job < ActiveRecord::Base
  establish_connection adapter: 'sqlite3', database: '../../db/development.sqlite3'
  self.table_name = :cacas_in_queues
  serialize :data, JSON
end

class CacasBackQueue < ActiveRecord::Base
  establish_connection adapter: 'sqlite3', database: '../../db/cacas_queue_development.sqlite3'
  self.table_name = :queue
  serialize :data, JSON

  def self.accomplished? job
    where(event_id: job.event_id, adapter: job.adapter, accomplished: true).size > 0
  end

  def self.create_or_update atts
    job_record = where(adapter: atts[:adapter], event_id: atts[:event_id]).first
    if job_record
      job_record.update atts
    else
      job_record = create atts
    end
    Cacas::JobProcessor.logger.debug "job_record #{job_record}"
    job_record
  end
end

class Cacas::JobProcessor
  cattr_accessor :logger

  class << self

    def process_all
      Job.where(accomplished: false).order(:id).reject {|j| CacasBackQueue.accomplished? j}
        .each do |job|
        logger.debug "processing job: #{job.inspect}"
        last_back_queue_ob = process job
        logger.debug "last_back_queue_ob #{last_back_queue_ob.inspect}"
        unless not(last_back_queue_ob.nil?) && last_back_queue_ob.accomplished
          logger.error "failed for: #{last_back_queue_ob.inspect}"
          break
        end
      end
    end

    def process job

      # logger.debug "Cacas::ADAPTERS.size #{Cacas::ADAPTERS.size} in #{__FILE__}"
      Cacas::ADAPTERS.each do |adapter|
        logger.debug "adapter #{adapter.inspect} in #{__FILE__}"
        back_queue_ob = adapter.process_job job
        logger.debug "back_queue_ob #{back_queue_ob.inspect}"
        break unless not(back_queue_ob.nil?) && back_queue_ob.accomplished
      end
      defined?(back_queue_ob) ? back_queue_ob : nil
    end
  end
end

adapters_dir = Pathname(File.dirname(__FILE__)).join('adapters')
Dir.entries(adapters_dir)
  .select {|d| File.directory? adapters_dir.join d}
  .reject {|d| /^\.{1,2}$/.match d}
  .each {|d| load File.join(adapters_dir, d, "#{d}.rb")}
Cacas.load_adapters
Cacas::ADAPTERS.each do |adptr|
  adptr.load_jobs
  adptr.logger = Cacas::JobProcessor.logger
end
