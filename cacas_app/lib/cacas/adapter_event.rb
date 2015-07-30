class Cacas::AdapterEvent
  class << self

    def config
      self.parent.config
    end
  end
end
