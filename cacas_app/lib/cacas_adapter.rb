class CacasAdapter
  class << self
    def job_details
      job_name = caller_locations(1,1)[0].label # name of calling method
      path_arr = [_adapter_dir, job_name, 'job_details.yml']
      var_name = "@#{job_name}_details"
      instance_variable_get(var_name) || _load_yaml(var_name, path_arr)
    end
    def config
      path_arr = [_adapter_dir, 'config.yml']
      var_name = :@config
      instance_variable_get(var_name) || _load_yaml(var_name, path_arr)
    end
    private
    def _adapter_dir
      "#{self.name.underscore}_stuff"
    end
    def _load_yaml(var_name, path_arr)
      yaml_path = File.join(Cacas::ADAPTERS_DIR, *path_arr)
      yaml = File.exists?(yaml_path) ? YAML::load_file(yaml_path).deep_symbolize_keys : {}
      instance_variable_set(var_name, yaml)
    end
  end
end
