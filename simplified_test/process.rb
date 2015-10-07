#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'
require 'active_support/core_ext/hash/indifferent_access'

class Event

  @@filename = 'data.yml'
  @@events = YAML::load_file(@@filename).map {|h| ActiveSupport::HashWithIndifferentAccess.new(h)}
  @@last_id = @@events[-1]['id']

  class << self

    def all
      @@events
    end

    def find id
      @@events.find {|e| e['id'] == id}
    end

    def where conds
      if conds.has_key? 'event'
        events = @@events.select {|e| e['event'] == conds['event'].to_s}
        conds.delete 'event'
      else
        events = @@events
      end
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
      File.write @@filename, to_yaml
    end
    def dump
      puts to_yaml
    end
    def to_yaml
      YAML::dump(@@events.map(&:deep_stringify_keys).map(&:to_hash)).gsub(/\n-/, "\n\n-")
    end
    def count
      @@events.size
    end
  end
end

class Hash
  def eid
    self['id']
  end
  def event
    self['event']
  end
  def method_missing name
    self['data'][name.to_s] if self.has_key?('data') && self['data'].has_key?(name.to_s)
  end
end

class Plugin
  class << self
    def inherited(sub)
      sub.instance_variable_set :@commands, {}
      sub.instance_variable_set :@event_handlers, {}
      sub.instance_variable_set :@after_job_handlers, {}
      sub.instance_variable_set :@event_definitions, {}
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
      event_name = event.event.to_sym
      _process event_name, event if @event_handlers.include? event_name
      _process2 event_name, event if @event_definitions.include? event_name
    end

    def _process event_name, event
      # inst = find_or_create event
      success = handler_context.instance_exec(event, &@event_handlers[event_name])
      # inst.save if success
    end

    def _process2  event_name, event
      definitions = @event_definitions[event_name]
      # p _recorded? event_name, event, definitions
      return if _recorded? event_name, event, definitions
      context = definitions[:handler_context_class].new(self, definitions[:attribute_mapping].map do |k,v|
        event.send k
      end)
      context.instance_exec event, &definitions[:handler]
      _record_it event, definitions if definitions[:record_it_with]
    end

    def _recorded? event_name, event, definitions
      rb_def = definitions[:recorded_by]
      attribs = rb_def[1].map do |curr, rec|
        rec_val = if curr.instance_of? Proc
                    curr.call event
                  else  # expecting symbol
                    event.send curr
                  end
        [rec, rec_val]
      end.to_h
      Event.where(attribs.merge('event' => rb_def.first)).first
    end

    def _record_it event, definitions
      event_name, mapping = definitions[:recorded_by]
      atts = _event_attrib_mapping event, mapping
      Event << ActiveSupport::HashWithIndifferentAccess.new(event: event_name.to_s, data:  atts)
    end

    def _event_attrib_mapping event, mapping
      mapping.map do |event_key, new_key|
        rec_val = if event_key.instance_of? Proc
                    event_key.call event
                  else                      # expecting symbol
                    event.send event_key
                  end
        [new_key, rec_val]
      end.to_h
    end

    def handler_context
      @handler_context ||= HandlerContext.new self
    end

    #####################################
    def define event_name, &block
      dc = DefineContext.new
      dc.instance_exec &block
      @event_definitions[event_name] = dc.data
    end
  end
end

class HandlerContext
  # class << self

  def initialize plugin_context, *args
    @plugin_context = plugin_context
  end
  def create_job e, creds
    # JobQueue.create event: e.event, event_id: e.id, data: creds
    puts "  should create job for event: #{e.event}, event_id: #{e.eid}"
  end
  def command name, data
    puts "  executing command: #{name}"
    plugin_context.execute name, data
  end
  def plugin_context
    @plugin_context
  end
  def ceid e
    "#{e.eid}-1"
  end
  # end
end

class DefineContext
  attr_reader :data
  def initialize # plugin_class #, event_name
    # @plugin_class = plugin_class
    # @event_name = event_name
    @data = {recorded_by: {}}
  end
  def recorded_by event_name, atts
    # @data[:recorded_by][event_name] = atts
    @data[:recorded_by] = [event_name, atts]
  end
  def record_it_with event_name, atts
    @data[:recorded_by] = [event_name, atts]
    @data[:record_it_with] = true
  end
  def provide attributes
    attribute_mapping = if attributes.is_a? Array
                          attributes.map {|i| [i,i]}.to_h
                        else
                          attributes
                        end
    @data[:attribute_mapping] = attribute_mapping
    @data[:handler_context_class] = Class.new(HandlerContext) do |c|
      @@atts = attribute_mapping.values
      attr_reader *attribute_mapping.values
      def initialize plugin_context, args
        # p @@atts, args
        @@atts.zip(args).each {|n,v| instance_variable_set "@#{n}", v}
        super
      end
    end
  end
  def handle &block
    @data[:handler] = block
  end
  def ceid
    proc {|e| "#{e.eid}-1"}
  end
end


class DovecotPlugin < Plugin


  define :AddedEmailServerInstance do
    record_it_with :AddedEmailServerInstanceRec, :eid => :event_id
    provide [:ip, :domain]
    handle do |e|
      create_job e, ip: ip, domain: domain
    end
  end


  define :RecruitedEmployee do
    recorded_by :CreatedEmployeeEmailAddress, :eid => :employee
    provide [:eid, :name, :surname, :companies]
    handle do |e|
      companies.each do |company|
        command :CreateEmployeeEmailAddress, name: name,
                                             surname: surname,
                                             company: company,
                                             employee: eid
      end
    end
  end

  # handle :RecruitedEmployee do |e|
  #   e.companies.each do |company|
  #     command :CreateEmployeeEmailAddress, name: e.name,
  #                                          surname: e.surname,
  #                                          company: company
  #   end
  # end


  command :CreateEmployeeEmailAddress do |data|
    data['address'] = "#{data[:name].downcase}.#{data[:surname].downcase}@hitchnhike.com"
    [:CreatedEmployeeEmailAddress, data.reject {|k,v| [:name, :surname].include? k}]
  end

  handle :CreatedEmployeeEmailAddress do |e|

    Event.by_event('AssociatedCompanyEmailServer')
      .select {|o| o.company == e.company}
      .each do |o|
        command :AddEmailAddressToServer, server: e.server,
                                          email: o.eid,
                                          address: e.address
      end
  end

  command :AddEmailAddressToServer do |data|
    [:AddedEmailAddressToServer, data]
  end


  handle :AddedEmailAddressToServer do |e|

    ip = Event.find_by_ceid(e.server).ip
    address = Event.find_by_ceid(e.email).address

    create_job e, ip: ip, address: address, path: e.path

  end

  # handle :AddedEmailServerInstance do |e|

  #   create_job e, ip: e.ip

  # end

  handle :AssociatedCompanyEmailServer do |e|

    Event.by_event('CreatedEmployeeEmailAddress')
      .select {|o| o.company == e.company}
      .each do |o|
        command :AddEmailAddressToServer, server: e.server,
                                          email: "#{o.eid}-1"
      end
  end
end


class RedminePlugin < Plugin

  handle :CreatedEmployeeRedmineAccount do |e|

    name      = Event.find_by_ceid(e.employee).name
    surname   = Event.find_by_ceid(e.employee).surname
    email     = Event.find_by_ceid(e.email).address
    ip        = Event.find_by_ceid(e.server).ip
    create_job e, name: name,
                  surname: surname,
                  # login: oh_lord_gimme_a_login(),
                  # password: oh_lord_gimme_a_password(),
                  email: email
  end
end


puts "Event.count: #{Event.count}"

Event.all.each do |e|

  puts "id: #{e.eid}, event: #{e.event}"

  [DovecotPlugin, RedminePlugin].each do |pl|
    pl.process e
  end
end

puts "Event.count: #{Event.count}"


# Event << {'event' => 'Dings', 'data' => {'email' => '5-1', 'server' => '2-1'}}

# p Event.where email: '5-1', server: '2-1'

Event.dump
