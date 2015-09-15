class Cacas::Command
  include ActiveModel::Model
  include ActiveModel::Dirty
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations

  class << self
    attr_reader :event_name, :actions
  end

  def self.involved_models models
    @models = models
    @attributes = []
    @plugin_models = {}
    models.each do |m,atts|
      atts << :id unless atts.include? :id
      att_syms = atts.map {|a| "#{m.to_s.underscore}__#{a}".to_sym}
      define_attribute_methods *att_syms
      attr_accessor *att_syms
      @attributes += att_syms
    end
  end

  # attr_accessor :solid
  attr_reader :plugin_models

  # def solid
  #   @solid = true
  # end

  def action model
    self.class.actions[model]
  end

  def plugin_models
    self.class.instance_variable_get :@plugin_models
  end

  def models
    mods = self.class.instance_variable_get(:@models).dup
    plugin_models.each do |name, a_models|
      a_models.each do |n, atts|
        mods[n] ||= []
        mods[n] += atts
      end
    end
    mods
  end

  def adapt plugin, mods
    plugin_models[plugin] =  {}
    mods.each do |m,atts|
      att_syms = atts.map {|a| "#{m}__#{plugin}_#{a}".to_sym}
      plugin_models[plugin][m] = atts.map {|a| "#{plugin}_#{a}".to_sym}
      self.class.class_eval do
        define_attribute_methods *att_syms
        attr_accessor *att_syms
      end
    end
    self
  end

  def adapted plugin, attribs # TODO: make use of attribs arg (filter @attributes)
    a_atts = plugin_models[plugin].map {|m, atts| atts.map {|a| "#{m}__#{a}"} }.flatten
    Hash[*(self.class.instance_variable_get(:@attributes)+a_atts).map {|a| [a, self.send(a)]}.flatten]
  end

  def command_name
    self.class.name.to_sym
  end

  def event_name
    self.class.event_name
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
