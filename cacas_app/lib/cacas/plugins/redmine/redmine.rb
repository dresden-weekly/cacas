module Cacas::Plugins::Redmine
  # puts __FILE__
  extend Cacas::Plugin
  extend Cacas::PluginConfig


  # vali_names = Proc.new do |record, attr, value|
  #   record.errors.add attr, 'starts with z.' if value.to_s[0] == ?z
  # end

  # VALIDATIONS = {
  #   validates_each: [ :name, :surname, vali_names ]
  # }
end
