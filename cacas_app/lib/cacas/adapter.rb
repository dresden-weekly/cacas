class Cacas::Adapter
  class << self
    attr_reader :event_name

    def config
      self.parent.config
    end
  end
end
