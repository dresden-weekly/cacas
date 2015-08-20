module Cacas


  ADAPTERS_DIR ||= Pathname(File.dirname(__FILE__)).join('adapters')
  ADAPTERS ||= []

  def self.load_adapters
    puts 'loading adapters'
    ADAPTERS.clear
    self::Adapters.constants.each {|a| ADAPTERS << self::Adapters.const_get(a)}
    ADAPTERS.sort!
  end

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
      Rails.logger.debug "command.user__id: #{command.user__id}"
      command.models.each do |m,atts|
        if [:update, :delete].include? command.action(m)
          ar_inst = m.to_s.camelize.constantize.find command.send("#{m.to_s.underscore}__id")
          atts.each do |a|
            val = ar_inst.send "#{a.to_s}"
            command.send "#{m.to_s.underscore}__#{a}=", val
          end
        end
      end
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
          ar_inst = if command.action(m) == :new
                      m.to_s.camelize.constantize.new
                    else
                      m.to_s.camelize.constantize.find command.send("#{m.to_s.underscore}__id")
                    end
          if [:new, :update].include? command.action(m)
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
          elsif command.action(m) == :delete
            ar_inst.delete
          end
        end

        # maybe transliterate and add validations errors of `ar_inst` to the
        # AM-attributes of `command`?
        if ar_messages.size > 0
          raise ActiveRecord::Rollback, "at least one validation failed!"
        end

        if ar_messages.size == 0 # && command.solid
          ev = Event.create! event: command.event_name, data: command.to_json
          ADAPTERS.each do |adapter|
            adapter.process_event ev, command
          end
        end
      end
      command
    end
  end

  module Adapters
  end
end
