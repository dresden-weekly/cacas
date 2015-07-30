module Cacas


  ADAPTERS_DIR ||= Pathname(File.dirname(__FILE__)).join('adapters')
  ADAPTERS ||= []

  def self.load_adapters
    ADAPTERS.clear
    self::Adapters.constants #.select {|c| /Adapter/ =~ c.to_s}
      .each {|a| ADAPTERS << self::Adapters.const_get(a)}
  end

  module Methods
    def cacas_command command
      [:before_validate_command, :validate_command, :after_validate_command].each do |cb|
        ADAPTERS.each do |adapter|
          command = adapter.process_callback cb, command
        end
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

  module Adapter
    def process_callback callback, command
      cmd_name = command.class.name.to_sym
      if self.class_variable_get(:@@EVENTS).include? cmd_name
        cmd_class = self.const_get(cmd_name)
        command = cmd_class.send callback, command if cmd_class.respond_to? callback
      end
      command
    end
  end

  module EventsLoader
    def self.included including # beautiful is different...
      dir = File.dirname(caller_locations(1,1)[0].path)
      %w(event.rb job.rb).map {|fn| Dir.glob File.join(dir, '**', fn)}
        .flatten.each {|path| load path}
      adapters = including.constants.select do |c|
        Class === including.const_get(c) && Cacas::AdapterEvent > including.const_get(c)
      end
      including.class_variable_set :@@EVENTS, adapters
    end
  end

  module Config
    private
    def _load_yaml(var_name, path_arr)
      yaml_path = File.join(ADAPTERS_DIR, *path_arr)
      # puts "yaml_path: #{yaml_path}"
      yaml = File.exists?(yaml_path) ? YAML::load_file(yaml_path).deep_symbolize_keys : {}
      instance_variable_set(var_name, yaml)
    end
  end

  module AdapterConfig
    include Config
    def config
      # puts "_adapter_dir #{_adapter_dir}"
      path_arr = [_adapter_dir, 'config.yml']
      var_name = :@config
      instance_variable_get(var_name) || _load_yaml(var_name, path_arr)
    end
    def _adapter_dir
      self.name.split('::').last.underscore
    end
  end

  module EventConfig
    include Config
    def job_details
      _details :job
    end
    def event_details
      _details :event
    end
    def _details kind
      path_arr = _event_dirs << "#{kind}_details.yml"
      var_name = "@#{kind}_details"
      instance_variable_get(var_name) || _load_yaml(var_name, path_arr)
    end
    def _event_dirs
      self.name.split('::')[-2,2].map &:underscore
    end
  end
end
