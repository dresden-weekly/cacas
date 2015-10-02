class Event < ActiveRecord::Base
  has_many :cacas_in_queues

  serialize :data,      JSON
  serialize :refchain,  JSON

  def refchain
    self.refchain
      .reverse
      .take_while {|i| i.first != self.cut_refchain_at}
      .reverse
  end
end
