#!/usr/bin/env ruby
# coding: utf-8

require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define do
  create_table :events do |table|
    table.column :event, :string
    table.column :data, :text
  end
  create_table :property_index do |table|
    table.column :event, :string
    table.column :event_id, :integer
    table.column :key, :string
    table.column :value, :text
  end
end

class PropertyIndex < ActiveRecord::Base
  self.table_name = :property_index
  serialize :value, JSON

  def self.add_event event
    event.data.each do |k,v|
      create event: event.event, event_id: event.id, key: k, value: v
    end
  end
end

class Event < ActiveRecord::Base
  after_create {|e| PropertyIndex.add_event e}

  serialize :data, JSON
  @@filename = 'cqrs-wikidot-example.yaml'
  YAML::load_file(@@filename).each do |h|
    create(event: h['event'], data: h['data'])
  end

end

PropertyIndex.all.each {|i| p i}

p PropertyIndex.where(event: 'GotMoneyFromAtm').ids

# Event.scope :amount, -> { Event.where(event: %w(GotMoneyFromAtm BoughtMetroTickets GrabbedALunch FoundACoin TookTaxi)) }
# Event.scope :gps, -> { Event.where(event: %w(FoundACoin)) }
# Event.scope :place, -> { Event.where(event: %w(GrabbedALunch)) }
# puts Event.amount.map {|e| e.data['amount']}.reduce &:+

arel_ev = Event.arel_table[:event]

arels = [arel_ev.in(%w(FoundACoin)),arel_ev.in(%w(GrabbedALunch))]

p Event.where(arels[0].or(arels[1])).order('id DESC').ids

# (mainly) same same dynamically:

none_arel = Event.arel_table[:id].eq(0)

p Event.where(arels.reduce(none_arel, &:or)).ids

p Event.where(
    arels.reduce(none_arel, &:or)
  ).map {|e| e.data['amount']}
   .reduce &:+


module DataCollection

  PropertyMapper = Struct.new :event, :meth, :trans

  class Entity
    class << self
      def inherited desc
        desc.instance_variable_set :@properties, {}
      end
      def add_property_mapper event, prop, meth, trans=nil
        @properties[prop] ||= []
        @properties[prop] << PropertyMapper.new(event, meth, trans || prop)
        attr_accessor prop unless instance_methods(false).include? prop
      end
      def mappers_for *props
        props.map {|p| [p, @properties[p]]}.to_h
      end
    end
  end

  class EventType
    class << self
      def contains entity_class, prop, meth, intern=nil
        entity_class.add_property_mapper event_name, prop, meth, intern
      end
      def event_name
        self.name.split('::')[-1].to_sym
      end
    end
  end

  class Portemonnaie < Entity
  end

  class GotMoneyFromAtm < EventType
    contains Portemonnaie, :amount, :+
  end
  class BoughtMetroTickets < EventType
    contains Portemonnaie, :amount, :+
  end
  class GrabbedALunch < EventType
    contains Portemonnaie, :amount, :+
  end
  class FoundACoin < EventType
    contains Portemonnaie, :amount, :+
  end
  class TookTaxi < EventType
    contains Portemonnaie, :amount, :+
  end
end

p DataCollection::Portemonnaie.mappers_for :amount
