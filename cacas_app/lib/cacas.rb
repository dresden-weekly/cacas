module Cacas


  ADAPTERS_DIR = Pathname(File.dirname __FILE__).join('cacas', 'adapters')
  ADAPTERS = []

  def self.load_adapters
    # Dir.entries(Cacas::ADAPTERS_DIR)
    #            .select {|d| File.directory? ADAPTERS_DIR.join d}.reject {|d| /^\.{1,2}$/.match d}
    #            .each {|d|  ADAPTERS << "#{d.camelize}Adapter".constantize }
    self::Adapters.constants.select {|c| /Adapter$/ =~ c.to_s}
      .each {|a| ADAPTERS << self::Adapters.const_get a}
  end

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

  module Adapters
  end

  module ModLoader
    def self.included by
      puts File.dirname(caller_locations(1,1)[0].path)
    end
    def scheise
      puts "na Sie wissen schon"
    end
  end
end
