module Cacas


  ADAPTERS_DIR ||= Pathname(File.dirname(__FILE__)).join('adapters')
  ADAPTERS ||= []

  def self.load_adapters
    puts 'loading adapters'
    ADAPTERS.clear
    self::Adapters.constants.each {|a| ADAPTERS << self::Adapters.const_get(a)}
    ADAPTERS.sort!
  end

  # Validation = Struct.new :name, :args, :proc

  # def self.get_validations command
  #   validations = {}
  #   ADAPTERS.each do |adapter|
  #     if adapter.have_event? command
  #       event = adapter.get_event command
  #       if event.constants.include? :VALIDATIONS
  #         validations.merge event.const_get :VALIDATIONS
  #       end
  #     end
  #   end
  # end


  def self.process_after_jobs
    JobQueue.where(accomplished: false).order(:id)
      .select {|j| CacasBackQueue.accomplished? j}
      .map {|j| [CacasBackQueue.get_matching(j), j]}
      .each do |queue_records|

        ADAPTERS.each do |adapter|
          adapter.process_after_job *queue_records
        end
      end
  end

  module Methods
    def cacas_prepare command
      ADAPTERS.each do |adapter|
        command = adapter.process_callback :prepare_command, command
      end
      command
    end

    def cacas_command command
      [:before_validate_command, :validate_command, :after_validate_command].each do |cb|
        ADAPTERS.each do |adapter|
          command = adapter.process_callback cb, command
        end
      end

      ar_messages = []
      ActiveRecord::Base.transaction do
        command.models.each do |m,atts|
          ar_inst = m.to_s.camelize.constantize.new
          atts.each do |a|
            val = command.send "#{m.to_s.underscore}__#{a}"
            ar_inst.send "#{a.to_s}=", val
          end
          if ar_inst.valid?
            ar_inst.save
            command.send "#{m.to_s.underscore}__id=", ar_inst.id
          else
            ar_messages += ar_inst.messages
          end
        end
        # maybe transliterate and add validations errors of `ar_inst` to the
        # AM-attributes of `command`?
        if ar_messages.size > 0
          raise ActiveRecord::Rollback, "at least one validation failed!"
        end
      end

      if ar_messages.size == 0 && command.solid
        ev = Event.create! event: command.event_name, data: command.to_json
        ADAPTERS.each do |adapter|
          adapter.process_event ev, command
        end
      end
      command
    end
  end

  module Adapters
  end

  module Config
    private
    def _get_config kind
      path_arr = _config_dirs << "#{kind}.yml"
      var_name = "@#{kind}_details"
      instance_variable_get(var_name) || _load_yaml(var_name, path_arr)
    end
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
      _get_config :config
    end
    def properties
      _get_config :properties
    end
    def _config_dirs
      [self.name.split('::').last.underscore]
    end
  end

  module EventConfig
    include Config
    def job_details
      _get_config :job_details
    end
    def event_details
      _get_config :event_details
    end
    def _config_dirs
      self.name.split('::')[-2,2].map &:underscore
    end
  end
end
