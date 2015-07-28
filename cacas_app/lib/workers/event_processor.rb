#!/usr/bin/env ruby

require 'rufus/scheduler'
require 'logger'
require File.expand_path('../../../config/environment.rb',  __FILE__)

Cacas::EventProcessor.logger = Logger.new File.expand_path('../../../log/cacas_event.log',  __FILE__), 10, 1024000
log = Cacas::EventProcessor.logger
log.datetime_format = "%Y-%m-%d %H:%M:%S"
log.formatter = proc { |severity, datetime, progname, msg|
  "#{datetime}: #{msg}\n"
}
log.level = Logger::DEBUG

scheduler = Rufus::Scheduler.new

scheduler.every '2s', :blocking => true, :first_in => '0s' do
  # log.info  "ENV['RAILS_ENV']: '#{ENV['RAILS_ENV']}'"
  Cacas::EventProcessor.process_events
end

scheduler.join
