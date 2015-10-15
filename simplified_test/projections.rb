#!/usr/bin/env ruby
# coding: utf-8

require 'active_record'
require 'active_support/inflector'
require 'pp'

DEBUG = [] # [:sql :events, :pmaps]

def dbg_msg type, msg
  puts msg if DEBUG.include? type
end

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define do
  create_table :events do |table|
    table.column :event, :string
    table.column :data, :text
    table.column :created_at, :timestamp
  end
  create_table :property_index do |table|
    table.column :event, :string
    table.column :event_id, :integer
    table.column :key, :string
    table.column :value, :text
    table.column :array_item, :boolean, default: false
  end
end

class PropertyIndex < ActiveRecord::Base
  self.table_name = :property_index
  serialize :value, JSON

  def self.add_event event
    event.data.each do |k,v|
      if v.instance_of? Array
        v.each do |i|
          create event: event.event, event_id: event.id, key: k, value: i, array_item: true
        end
      else
        create event: event.event, event_id: event.id, key: k, value: v
      end
    end
  end
end

class Event < ActiveRecord::Base
  after_create {|e| PropertyIndex.add_event e}

  serialize :data, JSON
  YAML::load_file('data.yml').each do |h|
    create(id: h['id'], event: h['event'], data: h['data'], created_at: h['created_at'])
  end
end


class Projection
  class << self
    attr_reader :identifiers, :events
    def inherited desc
      desc.instance_variable_set :@events, {}
      desc.instance_variable_set :@properties, []
      desc.instance_variable_set :@associations, {}
      desc.instance_variable_set :@origins, []
      # desc.instance_variable_set :@assoc_origins, []
      desc.instance_variable_set :@identifiers, {}
      desc.instance_variable_set :@finales, {}
    end
    def event event_name, &block
      @events[event_name] = {}
      pe = ProjectionEvent.new self, event_name
      block.call pe
    end
    def origin *events
      @origins += events
    end
    def finale events
      events.each {|event, prop| @finales[event] = prop}
    end
    def add_identifier event_name, prop
      @events[event_name][:identifier] = prop
      # @identifiers[event_name] = prop
    end
    def add_properties event_name, props
      @events[event_name][:properties] = props
      @events[event_name][:struct] = Struct.new *props.values
      @properties += props.keys
    end
    def add_handler event_name, handler
      @events[event_name][:handler] = handler
    end
    def add_association opts, event_name
      @associations[opts[:ass_name]] = opts[:ass_class]
      puts "opts: #{opts} event_name: #{event_name}"
      # @mappings["#{name}_ids".to_sym].each {|ev, pm| pm.id_association = entity_class.origins. include? ev}
      attr_reader name unless instance_methods(false).include? name
    end
    def plural_name
      self.name.underscore.pluralize.to_sym
    end
  end
end

class ProjectionEvent
  attr_reader :event_name, :projection_class
  def initialize projection_class, event_name
    @projection_class = projection_class
    @event_name = event_name
    @properties = []
  end
  def properties *props
    props_hash = props[-1].is_a?(Hash) ? props.pop : {}
    props_hash.merge!(props.map {|p| [p, p]}.to_h)
    @properties += props_hash.values
    projection_class.add_properties event_name, props_hash
  end
  def identifier prop
    projection_class.add_identifier event_name, prop
  end
  def updates entity_class, identifier, prop, meth, eprop=nil
    # identifies entity_class, identifier
    # entity_class.add_property_mapper event_name, prop, meth, eprop
  end
  def associates *args
    # Creates symmetrical associations between to Entity classes.
    # An optional arg can be given for each Entity class to
    # explicitly set a name for the association.

    args.unshift projection_class

    left_right = args.reject {|arg| arg.instance_of? Symbol}.map {|cls| {cls: cls}}

    get_args = proc do |this, other|
      args.shift
      this[:ass_name] = args[0].instance_of?(Symbol) ? args.shift : other[:cls].plural_name
      this[:ass_class] = other[:cls]
      this[:ass_identifier] = other[:cls].events[event_name][:identifier]
    end

    add_assoc = proc do |this, other|
      # eprop = other[:cls].identifiers[event_name]
      # this[:cls].add_property_mapper event_name, "#{this[:ass_name]}_ids".to_sym, append, eprop
      this[:cls].add_association this, event_name  #[:ass_name], other[:cls]
    end

    [get_args, add_assoc].each do |prozeder|
      2.times do
        prozeder.call *left_right
        left_right.reverse!
      end
    end
  end
  def project &block
    projection_class.add_handler event_name, block
  end
end


class Company < Projection
  origin :CreatedCompany, :AquiredCustomer
  finale CompanyBankrupted: :company

  event :CreatedCompany do |ev|
    ev.properties :name
    ev.project do |p,e|
      p.name = e.name
    end
  end

  event :AquiredCustomer do |ev|
    ev.properties :name
  end

  event :RecruitedEmployee do |ev|
    ev.identifier :companies
  end

  event :DismissedEmployee do |ev|
    ev.identifier :company
    ev.properties :company, employees_ids: :employee
    ev.project do |p,e|
      p.employees_ids.remove e.employee
    end
  end

  event :AssignedInterimStaff do |ev|
    ev.identifier :company
  end
end

class Employee < Projection
  origin :RecruitedEmployee
  finale DismissedEmployee: :employee

  event :RecruitedEmployee do |ev|
    ev.associates Company
    ev.properties :name, :surname
    ev.project do |p,e|
      p.name = e.name
      p.surname = e.surname
    end
  end

  event :UpdatedEmployee do |ev|
    ev.identifier :employee
    ev.properties :name, :surname
    ev.project do |p,e|
      p.name = e.name
      p.surname = e.surname
    end
  end

  event :DismissedEmployee do |ev|
    ev.identifier :employee
  end

  event :AssignedInterimStaff do |ev|
    ev.identifier :employees
    ev.associates Company
  end
end
