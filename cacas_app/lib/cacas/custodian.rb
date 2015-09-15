module Cacas::Plugin
  cattr_accessor :logger

  def process_callback callback, command
    if have_adapter? command
      cmd_class = get_adapter command
      command = cmd_class.send callback, command if cmd_class.respond_to? callback
    end
    command
  end

  def process_event event, command
    if have_adapter? command
      cmd_class = get_adapter command
      cmd_class.process_event event, command
    end
  end

  def process_job job
   # Cacas::JobProcessor.logger.debug("have_job? #{have_job? job} job")
    if concerned?(job) && have_job?(job)
      job_class = get_job job
      # Cacas::JobProcessor.logger.debug("RUNNING #{job.inspect}")
      job_class.run job
    else
      nil
    end
  end

  def process_after_job back_queue, job
    if concerned?(job) && have_job?(job)
      cmd_class = get_adapter job
      cmd_class.after_job back_queue, job
    end
  end

  def run_after
    @run_after ||= self.properties[:run_after] || []
  end


  def load_sagas
    dir = File.dirname(caller_locations(1,1)[0].path)
    puts dir
    Cacas::Helpers.load_subdir_rbs Pathname.new dir
    # classes = self.constants.select do |c|
    #   Class === self.const_get(c) && ActiveRecord::Base > self.const_get(c)
    # end
  end

  def load_adapters
    _load_files :adapter
    _load_classes :adapter
  end

  def load_jobs
    _load_files :job
    _load_classes :job
  end

  def _load_files kind
    dir = File.dirname(caller_locations(1,1)[0].path)
    Dir.glob(File.join(dir, '**', "#{kind}.rb")).each {|path| load path}
  end
  def _load_classes kind
    base = Cacas.const_get kind.to_s.camelize
    classes = self.constants.select do |c|
      Class === self.const_get(c) && base > self.const_get(c)
    end
    self.class_variable_set "@@#{kind.to_s.pluralize.upcase}", classes
    class2event_name = Hash[*(classes.map {|c| [c, self.const_get(c).event_name]}).flatten]
    self.class_variable_set "@@#{kind}2event_name", class2event_name
    self.class_variable_set "@@event_name2#{kind}", class2event_name.invert
  end

  def concerned? job
    name.split('::')[-1].underscore == job.plugin
  end

  def have_adapter? command
    self.class_variable_get(:@@COMMAND_EVENTS).include? command.command_name
  end

  def get_adapter c_or_j      # Command or Job
    if c_or_j.is_a? Cacas::Command
      self.const_get(c_or_j.command_name)
    else
      self.const_get(self.class_variable_get(:@@event_name2adapter)[c_or_j.event])
    end
  end

  def have_job? job
   # Cacas::JobProcessor.logger.debug("in have_job? #{"#{job.event}Job".to_sym} job")
    self.class_variable_get(:@@JOBS).include? "#{job.event}Job".to_sym
  end

  def get_job job
    self.const_get("#{job.event}Job".to_sym)
  end
end
