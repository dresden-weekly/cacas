
module DiscoSaga::Meta
  module Condition
    class Base < BasicObject
      attr_reader :event_name

      def initialize event_name
        @event_name = event_name
      end

      def method_missing method, *args
        if args.empty?
          Element.new self, method
        else
          super
        end
      end
    end

    class Element
      attr_reader :base, :name

      def initialize base, name
        @base = base
        @name = name
      end

      def == other
        Equals.new self, other
      end
    end

    class Equals
      attr_reader :left, :right

      def initialize left, right
        @left = left
        @right = right
      end

    end
  end

  class Trigger < Condition::Base
  end

  class Result < Condition::Base
    attr_reader :trigger

    def initialize event_name, block
      @trigger = block
      super event_name
    end
  end

  class Saga
    attr_reader :triggers, :result, :conditions
    attr_reader :job_name, :job_block

    def initialize
      @triggers = {}
      @result = nil
      @conditions = []
      @job_name = nil
      @job_block = nil
    end

    def trigger event_name
      raise "duplicate trigger" if @triggers.key? event_name
      @triggers[event_name] = Trigger.new event_name
    end

    def where condition
      raise "is not a condition" unless condition.is_a? Condition::Equals
      @conditions << condition
      self
    end

    def job name, &block
      raise "no name given" if name.nil?
      raise "only one job allowed" unless job_name.nil?
      @job_name = name
      @job_block = block
    end

    def result event_name, &block
      raise "saga can only have one result" unless @result.nil?
      raise "you have to give a block" unless block_given?
      @result = Result.new(event_name, block)
    end
  end
end