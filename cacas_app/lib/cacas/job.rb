class Cacas::Job
  class << self
    attr_reader :event_name

    def config
      self.parent.config
    end
  end
end
