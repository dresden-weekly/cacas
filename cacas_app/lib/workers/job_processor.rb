#!/usr/bin/env ruby

require 'rufus/scheduler'
require 'logger'
require_relative '../cacas/job_processor.rb'

Cacas::JobProcessor.logger = Logger.new File.expand_path('../../../log/cacas_event.log',  __FILE__), 10, 1024000
log = Cacas::JobProcessor.logger
log.datetime_format = "%Y-%m-%d %H:%M:%S"
log.formatter = proc { |severity, datetime, progname, msg|
  "#{datetime}: #{msg}\n"
}
log.level = Logger::DEBUG

scheduler = Rufus::Scheduler.new

scheduler.every '1s', :blocking => true, :first_in => '0s' do
  Cacas::JobProcessor.process_all
end

scheduler.join
