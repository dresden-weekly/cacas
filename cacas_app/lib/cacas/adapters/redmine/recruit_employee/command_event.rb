class Cacas::Adapters::Redmine::RecruitEmployee < Cacas::CommandEvent
  extend Cacas::EventConfig
  @event_name = 'RecruitedEmployee'

  class << self
    def prepare_command(command)
      command.adapt(:redmine, user: [:login, :mail])
    end
    def before_validate_command(command)
      if command.user__redmine_login.blank?
        command.user__redmine_login = "#{command.user__name.downcase}.#{command.user__surname.downcase}"
      end
      if command.user__redmine_mail.blank?
        command.user__redmine_mail = "#{command.user__redmine_login}@hicknhack-software.com"
      end
      command
    end
    def validate_command(command)
      command
    end
    def after_validate_command(command)
      command
    end
    def process_event(event, command)
      # Job.create(:redmine, event.adapted(:login, :email).merge(event.attributes(:surname, :name)))
      JobQueue.create(adapter: :redmine, event: event.event, event_id: event.id, data: command.adapted(:redmine, [:surname, :name]))
    end
    def after_job(back_queue, job)
      # User.find(event.id).update_adapter_attributes(:redmine, id: job_result[:id])
      succ = User.find(back_queue.data['user__id']).update(redmine_id: back_queue.data['user__redmine_id'])
      job.update(accomplished: true) if succ
    end
  end
end
