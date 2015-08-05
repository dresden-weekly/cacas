module Cacas::Adapter
  cattr_accessor :logger

  def process_callback callback, command
    if have_command_event? command
      cmd_class = get_command_event command
      command = cmd_class.send callback, command if cmd_class.respond_to? callback
    end
    command
  end

  def process_event event, command
    if have_command_event? command
      cmd_class = get_command_event command
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
      cmd_class = get_command_event job
      cmd_class.after_job back_queue, job
    end
  end

  include Comparable

  def <=> other
    # puts "#{self.name.inspect} <=> #{other.name} after.inspect #{after.inspect} other.after.inspect #{other.after.inspect}"
    if run_after.include?(other.name)
      1
    elsif other.run_after.include?(self.name)
      -1
    else
      0
    end
  end

  def run_after
    @run_after ||= self.properties[:run_after] || []
  end


  def load_command_events
    _load_files :command_event
    _load_classes :command_event
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
    # base = Cacas.const_get kind.to_s.camelize
    # dir = File.dirname(caller_locations(1,1)[0].path)
    # Dir.glob(File.join(dir, '**', "#{kind}.rb")).each {|path| load path}
    base = Cacas.const_get kind.to_s.camelize
    classes = self.constants.select do |c|
      Class === self.const_get(c) && base > self.const_get(c)
    end
    # puts "dir #{Dir.glob(File.join(dir, '**', "#{kind}.rb")).size} #{classes.size}"
    self.class_variable_set "@@#{kind.to_s.pluralize.upcase}", classes
    class2event_name = Hash[*(classes.map {|c| [c, self.const_get(c).event_name]}).flatten]
    self.class_variable_set "@@#{kind}2event_name", class2event_name
    self.class_variable_set "@@event_name2#{kind}", class2event_name.invert
  end

  def concerned? job
    name.split('::')[-1].underscore == job.adapter
  end

  def have_command_event? command
    self.class_variable_get(:@@COMMAND_EVENTS).include? command.command_name
  end

  def get_command_event c_or_j      # Command or Job
    if c_or_j.is_a? Cacas::Command
      self.const_get(c_or_j.command_name)
    else
      self.const_get(self.class_variable_get(:@@event_name2command_event)[c_or_j.event])
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
