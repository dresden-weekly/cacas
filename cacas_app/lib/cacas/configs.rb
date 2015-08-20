module Cacas
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
