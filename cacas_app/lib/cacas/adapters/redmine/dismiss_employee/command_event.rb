class Cacas::Adapters::Redmine::DismissEmployee < Cacas::CommandEvent
  extend Cacas::EventConfig
  @event_name = 'DismissedEmployee'

  class << self
    def prepare_command(command)
      command.adapt(:redmine, user: [:id])
    end
    def before_validate_command(command)
      command
    end
    def validate_command(command)
      command
    end
    def after_validate_command(command)
      command
    end
    def process_event(event, command)
      JobQueue.create(adapter: :redmine, event: event.event, event_id: event.id, data: command.adapted(:redmine, [:id]))
    end
    def after_job(back_queue, job)
        job.update(accomplished: true)
    end
  end
end
