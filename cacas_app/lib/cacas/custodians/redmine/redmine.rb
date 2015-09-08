module Cacas::Custodians::Redmine
  # puts __FILE__
  extend Cacas::Custodian
  extend Cacas::CustodianConfig


  # vali_names = Proc.new do |record, attr, value|
  #   record.errors.add attr, 'starts with z.' if value.to_s[0] == ?z
  # end

  # VALIDATIONS = {
  #   validates_each: [ :name, :surname, vali_names ]
  # }
end
