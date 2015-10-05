#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'

class Event

  @@filename = 'data.yml'
  @@events = YAML::load_file @@filename
  @@last_id = @@events[-1]['id']

  class << self

    def all
      @@events
    end

    def find id
      @@events.find {|e| e['id'] == id}
    end

    def where conds
      @@events.select do |e|
        conds.reduce(true) do |r,cond|
          r && e['data'][cond[0].to_s] == cond[1]
        end
      end
    end

    def by_event event
      @@events.select {|e| e['event'] == event.to_s}
    end

    def find_by_ceid ceid
      find ceid.split('-').first.to_i
    end

    def << event
      @@last_id += 1
      event = ([['id', @@last_id]] + event.to_a).to_h
      @@events << event
    end

    def save
      File.write @@filename, YAML::dump(@@events).gsub(/\n-/, "\n\n-")
    end
    def count
      @@events.size
    end
  end
end

class Plugin
  class << self
    def inherited(sub)
      sub.instance_variable_set :@create_on, {}
      sub.instance_variable_set :@commands, {}
      sub.instance_variable_set :@event_handlers, {}
      sub.instance_variable_set :@after_job_handlers, {}
    end

    def handle name, &block
      @event_handlers[name] = block
    end

    def command name, &block
      @commands[name] = block
    end

    def after_job name, &block
      @after_job_handlers[name] = block
    end

    def handles? event_name
      @event_handlers.include? event_name
    end

    def execute command_name, data
      populate *@commands[command_name].call(data)
    end

    def populate event_name, data
      Event << {'event' => event_name.to_s, 'data' => data}
    end

    def process event
      event_name = event['event'].to_sym
      _process event_name, event if @event_handlers.include? event_name
    end

    def _process event_name, event
      # inst = find_or_create event
      success = handler_context.instance_exec(event, &@event_handlers[event_name])
      # inst.save if success
    end

    def handler_context
      @handler_context ||= HandlerContext.new self
    end
  end
end

class HandlerContext
  # class << self

  def initialize plugin_context
    @plugin_context = plugin_context
  end
  def create_job e, creds
    # JobQueue.create event: e.event, event_id: e.id, data: creds
    puts "  should create job for event: #{e['event']}, event_id: #{e['id']}"
  end
  def command name, data
    puts "  executing command: #{name}"
    plugin_context.execute name, data
  end
  def plugin_context
    @plugin_context
  end
  # end
end



class DovecotPlugin < Plugin

  handle :RecruitedEmployee do |e|

    e['data']['companies'].each do |company|

      command :CreateEmployeeEmailAddress, name: e['data']['name'],
                                           surname: e['data']['surname'],
                                           company: company
    end
  end

  command :CreateEmployeeEmailAddress do |data|
    [:CreatedEmployeeEmailAddress, data]
  end

  handle :CreatedEmployeeEmailAddress do |e|

    Event.by_event('AssociatedCompanyEmailServer')
      .select {|o| o['data']['company'] == e['data']['company']}
      .each do |o|
        command :AddEmailAddressToServer, server: e['data']['server'],
                                          email: "#{o.id}-1",
                                          address: e['data']['address']
      end
  end

  command :AddEmailAddressToServer do |data|
    [:AddedEmailAddressToServer, data]
  end

  handle :AddedEmailAddressToServer do |e|

    ip = Event.find_by_ceid(e['data']['server'])['data']['ip']
    address = Event.find_by_ceid(e['data']['email'])['data']['address']

    create_job e, ip: ip, address: address, path: e['data']['path']

  end

  handle :AddedEmailServerInstance do |e|

    create_job e, ip: e['data']['ip']

  end

  handle :AssociatedCompanyEmailServer do |e|

    Event.by_event('CreatedEmployeeEmailAddress')
      .select {|o| o['data']['company'] == e['data']['company']}
      .each do |o|
        command :AddEmailAddressToServer, server: e['data']['server'],
                                          email: "#{o['id']}-1"
      end
  end
end


class RedminePlugin < Plugin

  handle :CreatedEmployeeRedmineAccount do |e|

    name      = Event.find_by_ceid(e['data']['employee'])['data']['name']
    surname   = Event.find_by_ceid(e['data']['employee'])['data']['surname']
    email     = Event.find_by_ceid(e['data']['email'])['data']['address']
    ip        = Event.find_by_ceid(e['data']['server'])['data']['ip']
    create_job e, name: name,
                  surname: surname,
                  # login: oh_lord_gimme_a_login(),
                  # password: oh_lord_gimme_a_password(),
                  email: email
  end
end


puts "Event.count: #{Event.count}"

Event.all.each do |e|

  puts "id: #{e['id']}, event: #{e['event']}"

  [DovecotPlugin, RedminePlugin].each do |pl|
    pl.process e
  end
end

puts "Event.count: #{Event.count}"


# Event << {'event' => 'Dings', 'data' => {'email' => '5-1', 'server' => '2-1'}}

# p Event.where email: '5-1', server: '2-1'

# Event.save
