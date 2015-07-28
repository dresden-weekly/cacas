class Cacas::Command
  include ActiveModel::Model
  include ActiveModel::Dirty
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations

  class << self
    attr_reader :event_name
  end

  def self.involved_models models
    @models = models
    @attributes = []
    models.each do |m,atts|
      att_syms = atts.map {|a| "#{m.to_s.underscore}__#{a}".to_sym}
      define_attribute_methods *att_syms
      # attr_accessor *att_syms
      @attributes += att_syms
    end
  end

  def self.form_name(name)
    define_singleton_method(:model_name) do
      @_model_name ||= begin
        namespace = parents.find do |n|
          n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
        end
        ActiveModel::Name.new(self, namespace, name)
     end
    end
  end

  attr_accessor :solid
  attr_reader :adapter_fields

  def solid
    @solid || true
  end

  def add_adapter_fields fields
    @adapter_fields ||= {}
    @adapter_fields.merge fields
  end

  def event_name
    self.class.event_name
  end

  def save
    succ = true
    models = self.class.instance_variable_get :@models
    ActiveRecord::Base.transaction do
      models.map do |m,atts|
        ar_inst = m.to_s.capitalize.constantize.new
        atts.each do |a|
          val = self.send "#{m.to_s.underscore}__#{a}"
          ar_inst.send "#{a.to_s}=", val
        end
        succ &&= ar_inst.save
      end
    end
    # maybe transliterate errors to the AM-attributes?
    succ
  end

  def attributes
    atts = self.class.instance_variable_get :@attributes
    Hash[*atts.reject {|a| self.send(a).nil?}.map {|a| [a, nil]}.flatten]
  end

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end
end
