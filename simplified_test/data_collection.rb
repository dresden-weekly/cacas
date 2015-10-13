#!/usr/bin/env ruby
# coding: utf-8

require 'active_record'
require 'active_support/inflector'
require 'pp'

DEBUG = [:sql]

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


PropertyMapper = Struct.new :event, :prop, :meth, :eprop, :id_origin, :identifier, :id_association

class Entity
  attr_reader :id
  class << self
    attr_reader :identifiers, :origins, :associations, :assoc_origins
    def inherited desc
      desc.instance_variable_set :@mappings, {}
      desc.instance_variable_set :@associations, {}
      desc.instance_variable_set :@origins, []
      desc.instance_variable_set :@assoc_origins, []
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
    def add_association name, entity_class
      @associations[name] = entity_class
      @mappings["#{name}_ids".to_sym].each {|ev, pm| pm.id_association = entity_class.origins. include? ev}
      attr_reader name unless instance_methods(false).include? name
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
      @origins += events
    end
    def finale *events
      events.each {|event, prop| @finales[event] = prop}
    end
    def plural_name
      self.name.underscore.pluralize.to_sym
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
    # def appends entity_class, prop
    # end
    def associates *args
      # Creates symmetrical associations between to Entity classes.
      # An optional params can be given for each Entity class to
      # explicitly set a name for the association.

      left_right = args.reject {|arg| arg.instance_of? Symbol}.map {|cls| {cls: cls}}

      get_args = proc do |this, other|
        args.shift
        this[:ass_name] = args[0].instance_of?(Symbol) ? args.shift : other[:cls].plural_name
      end

      add_assoc = proc do |this, other|
        eprop = other[:cls].identifiers[event_name]
        # abort "identifier must be set for #{other[:cls]} to assosciate with #{this[:cls]} by #{event_name}" unless eprop
        this[:cls].add_property_mapper event_name, "#{this[:ass_name]}_ids".to_sym, append, eprop
        this[:cls].add_association this[:ass_name], other[:cls]
      end

      [get_args, add_assoc].each do |prozeder|
        2.times do
          prozeder.call *left_right
          left_right.reverse!
        end
      end
    end

    def event_name
      self.name.split('::')[-1].to_sym
    end

    def override
      proc do |old, new|
        # puts "override #{old} with #{new}";
        new
      end
    end
    def append
      proc do |old, new|
        # puts "append #{new} to #{old}";
        old ||= []
        (old << new).flatten
      end
    end
  end
end

module EntityCollector


  EV_EV = Event.arel_table[:event]
  EV_ID = Event.arel_table[:id]
  EV_NONE = Event.arel_table[:id].eq(0)
  IND_EV = PropertyIndex.arel_table[:event]
  # IND_EID = PropertyIndex.arel_table[:event_id]
  IND_KEY = PropertyIndex.arel_table[:key]
  IND_VAL = PropertyIndex.arel_table[:value]
  IND_NONE = PropertyIndex.arel_table[:id].eq(0)

  def self.get e_class, ids, *props
    assocs = props[-1].instance_of?(Hash) ? props.pop : {}
    assocs.each_key {|k| props << "#{k}_ids".to_sym}
    ents = ids.map {|id| [id, {}]}.to_h
    p_maps = e_class.mappers_by_event props
    # p "________________________________________", props, p_maps
    index_arels = e_class.identifiers
                  .select {|e,p| p_maps.keys.include? e}
                  .map {|e,p| IND_EV.eq(e).and(IND_KEY.eq(p)).and(IND_VAL.in(ids))}
                  .reduce(IND_NONE, &:or)
    arel_upds = EV_ID.in PropertyIndex.select(:event_id).where(index_arels).map(&:event_id)
    arel_origs = EV_ID.in ids
    dbg_msg :sql, index_arels.to_sql
    dbg_msg :sql, arel_origs.or(arel_upds).to_sql
    Event.where(arel_origs.or(arel_upds)).order(:id).all.each do |ev|
      # p ev
      p_maps[ev.event.to_sym].each do |pm|
        # puts "#{pm.prop} #{pm.eprop}"
        idents = _ids(e_class, ids, ev, pm)
        idents.each do |id|
          new = pm.id_association ? ev.id : ev.data[pm.eprop.to_s]
          old = ents[id][pm.prop]
          if pm.meth.instance_of? Proc
            ents[id][pm.prop] = pm.meth.call(old, new)
          else
            old.send pm.meth, new
          end
        end
      end
    end
    instances = _instantiate e_class, ents
    puts "______________ get associations ___________________"
    assocs.each do |ass_name, propsies|
      ass_class = e_class.associations[ass_name]
      instances.each do |inst|
        ass_ids = inst.send "#{ass_name}_ids"
        next unless ass_ids
        inst.instance_variable_set("@#{ass_name}", get(ass_class, ass_ids, *propsies))
      end
    end
    instances
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

class Company < Entity
  origin :CreatedCompany, :AquiredCustomer
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

class AquiredCustomer < EventType
  contains Company, :name, override
end

class RecruitedEmployee < EventType
  identifies Company, :companies
  contains Employee, :name, override
  contains Employee, :surname, override
  # contains Employee, :companies_ids, override, :companies
  associates Employee, Company
  # associates Company, Employee
end

class UpdatedEmployee < EventType
  identifies Employee, :employee
  contains Employee, :name, override
  contains Employee, :surname, override
end

class AssignedInterimStaff < EventType
  identifies Employee, :employees
  identifies Company, :company
  # contains Employee, :companies_ids, append, :company
  # associates Employee, :company, Company
  associates Employee, Company
  # associates Company, Employee
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

# p Employee.instance_variable_get :@mappings

# p EntityCollector::get Employee, [7,12], :name, :surname, :companies_ids
pp EntityCollector::get Employee, [7,12], :name, :surname, companies: [:name]
pp EntityCollector::get Company, [1,8], :name, employees: [:name, :surname]
