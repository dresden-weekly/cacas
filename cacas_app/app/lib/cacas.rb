module Cacas

  # ADAPTERS = self::Adapters.constants.select {|c| /Adapter$/ =~ c.to_s}
  #            .map {|a| self::Adapters.const_get a}

  ADAPTERS_DIR = File.join(File.dirname(__FILE__), 'cacas', 'adapters')

  ADAPTERS = Dir.entries(ADAPTERS_DIR)
             .select {|d| /^[^#.].+_adapter.rb$/ =~ d}
             .map {|d| "#{d.sub(/\.rb$/,'').camelize}".constantize}


  module Methods
    def cacas_command command
      cmd_name = command.class.to_s.underscore
      ADAPTERS.each do |adapter|
        command = adapter.send cmd_name, command if adapter.respond_to? cmd_name
      end
      command.save
      logger.info "---------command.solid #{command.solid}"
      Event.create! event: command.event_name, data: command.to_json if command.solid
      command
    end

    def process_events

    end

    def process_event event
      # ar_model = event.event.constantize.new
      # ar_model.from_json event.data
      # ADAPTERS.each do |adapter|
      #   ar_model = adapter.send event.event.underscore, ar_model if adapter.respond_to? event.event.underscore
      # end
    end

    def process_job event
      ar_model = event.event.constantize.new
      ar_model.from_json event.data
      ADAPTERS.each do |adapter|
        ar_model = adapter.send event.event.underscore, ar_model if adapter.respond_to? event.event.underscore
      end
    end
  end
end
