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
    create(id: h['id'], event: h['event'], data: h['data'])
  end

end


PropertyMapper = Struct.new :event, :prop, :meth, :eprop, :id_origin, :identifier

class Entity
  attr_reader :id
  class << self
    attr_reader :identifiers, :origins
    def inherited desc
      desc.instance_variable_set :@mappings, {}
      desc.instance_variable_set :@origins, []
      desc.instance_variable_set :@identifiers, {}
      desc.instance_variable_set :@finales, {}
    end
    def add_property_mapper event, prop, meth, eprop=nil
      @mappings[prop] ||= {}
      @mappings[prop][event] = PropertyMapper.new(event,
                                                  prop,
                                                  meth,
                                                  eprop || prop,
                                                  origins.include?(event),
                                                  identifiers[event])
      attr_reader prop unless instance_methods(false).include? prop
    end
    def add_identifier event, prop
      @mappings.each {|p,em| em[event].identifier = prop if em.has_key? event}
      @identifiers[event] = prop
    end
    def mappers_by_event props
      res = {}
      props.each do |p|
        @mappings[p].each do |ev, pm|
          res[ev] ||= []
          res[ev] << pm
        end
      end
      res
    end
    def origin *events
      events.each {|event| @origins << event}
    end
    def finale *events
      events.each {|event, prop| @finales[event] = prop}
    end
  end
end

class Association < Entity
end

class EventType
  class << self
    def contains entity_class, prop, meth, eprop=nil
      entity_class.add_property_mapper event_name, prop, meth, eprop
    end
    def identifies entity_class, prop
      entity_class.add_identifier event_name, prop
    end
    def associates *args
    end
    def event_name
      self.name.split('::')[-1].to_sym
    end

    def override
      proc {|old, new| new}
    end
    def append
      proc do |old, new|
        old ||= []
        old << new
      end
    end
  end
end

class Company < Entity
  origin :CreatedCompany
  finale CompanyBankrupted: :company
end

class Employee < Entity
  origin :RecruitedEmployee
  finale DismissedEmployee: :employee, CompanyBankrupted: :employees
end

class EmployeeCompanies < Association
end

class EmailServer < Entity
  origin :AddedEmailServerInstance
end

class RedmineServerInstance < Entity
  origin :AddedRedmineServerInstance
end

class CompanyEmailServer < Association
  origin :AssociatedCompanyEmailServer
end


# AssociatedCompanyRedmineServer CreatedProject RecruitedEmployee CreatedEmployeeEmailAddress AddedEmailAddressToServer CreatedEmployeeRedmineAccount GotRedmineUserAccountId AddedProjectsToEmployee UpdatedEmployee StartedProject AssignedEmployeesToProject

class CreatedCompany < EventType
  contains Company, :name, override
end

class RecruitedEmployee < EventType
  contains Employee, :name, override
  contains Employee, :surname, override
  contains Employee, :companies_ids, override, :companies
  associates Employee, Company: :companies
end

class UpdatedEmployee < EventType
  identifies Employee, :employee
  contains Employee, :name, override
  contains Employee, :surname, override
end

class AssignedInterimStaff < EventType
  identifies Employee, :employees
  contains Employee, :companies_ids, append, :company
  associates Employee: :employees, Company: :companies
end

class AddedEmailServerInstance < EventType
  contains EmailServer, :domain, override
  contains EmailServer, :ip, override
end

class AddedRedmineServerInstance < EventType
  contains RedmineServerInstance, :ip, override
end

class AssociatedCompanyEmailServer < EventType
  contains CompanyEmailServer, :email_server, append
end

module EntityCollector


  AREL_EV = Event.arel_table[:event]
  AREL_ID = Event.arel_table[:id]
  AREL_NONE = Event.arel_table[:id].eq(0)
  IND_EV = PropertyIndex.arel_table[:event]
  # IND_EID = PropertyIndex.arel_table[:event_id]
  IND_KEY = PropertyIndex.arel_table[:key]
  IND_VAL = PropertyIndex.arel_table[:value]
  IND_NONE = PropertyIndex.arel_table[:id].eq(0)

  def self.get e_class, ids, *props
    ents = ids.map {|id| [id, {}]}.to_h
    p_maps = e_class.mappers_by_event props
    index_arels = e_class.identifiers
                  .select {|e,p| p_maps.keys.include? e}
                  .map {|e,p| IND_EV.eq(e).and(IND_KEY.eq(p)).and(IND_VAL.in(ids))}
                  .reduce(IND_NONE, &:or)
    arel_upds = AREL_ID.in PropertyIndex.select(:event_id).where(index_arels).map(&:event_id)
    arel_origs = AREL_ID.in ids
    Event.where(arel_origs.or(arel_upds)).order(:id).all.each do |ev|
      p_maps[ev.event.to_sym].each do |pm|
        idents = _ids(e_class, ids, ev, pm)
        idents.each do |id|
          ents[id][pm.prop] = pm.meth.call(ents[id][pm.prop], ev.data[pm.eprop.to_s])
        end
      end
    end
    _instantiate e_class, ents
  end

  def self._instantiate e_class, ents
    ents.map do |id, props|
      ent = e_class.new
      ent.instance_variable_set :@id, id
      props.each {|k,v| ent.instance_variable_set "@#{k}", v}
      ent
    end
  end

  def self._ids e_class, ids, event, pm
    if pm.id_origin
      [ event.id ]
    else
      value = event.data[pm.identifier.to_s]
      value.is_a?(Array) ? (ids & value) : [ value ]
    end
  end
end

p EntityCollector::get Employee, [7,12], :name, :surname, :companies_ids
