class Cacas::Saga < ActiveRecord::Base
  self.abstract_class = true

  attr_reader :event_handlers

  class << self

    def inherited(sub)
      sub.instance_variable_set :@finders, {}
      sub.instance_variable_set :@event_handlers, {}
      sub.instance_variable_set :@after_job_handlers, {}
    end

    def default_finder mapping
      @finders[:default] = mapping
    end

    def set_finder_for *args, &block
      event_name = args.shift
      if block_given?
        @finders[event_name] = block
      else
        @finders[event_name] = args.shift
      end
    end

    def finder_for event
      if @finders.include? event.sym_name
        @finders[event.sym_name]
      else
        @finders[:default]
      end
    end

    def on_event name, &block
      @event_handlers[name] = block
    end

    def after_job name, &block
      @after_job_handlers[name] = block
    end

    def handles? event_name
      @event_handlers.include? event_name
    end

    def find_or_create event
      search = Hash[*finder_for(event).map {|k,v| [v, event.data[k]]}.flatten]
      self.where(search).first || self.new
    end

    def handle event
      inst = find_or_create event
      inst.instance_exec(event, &@event_handlers[event.sym_name])
      inst.save
    end
  end
end
