module Cacas::Custodians::Redmine::DismissEmployeeSaga

  # on_event :DismissedEmployee do |ev|
  #   saga = ...
  # end
  #
  # on_event :MailboxRemoved do |ev|
  #   find_or_create(...) do |saga|
  #     saga.mailbox_removed = true
  #   end
  # end
  #
  # def is_complete?
  #   mailbox_removed && employee_dismissed
  # end
  #
  # def on_completed
  #   run DismissCommand.new
  # end
  #
  class DismissEmployee < Cacas::Adapter
    extend Cacas::EventConfig
    @event_name = 'DismissedEmployee'

    class << self
      # def prepare_command(command)
      #   command.adapt(:redmine, user: [:id])
      # end
      # def before_validate_command(command)
      #   command
      # end
      # def validate_command(command)
      #   command
      # end
      # def after_validate_command(command)
      #   command
      # end
      def process_event(event, command)
        JobQueue.create(custodian: :redmine, event: event.event, event_id: event.id, data: command.adapted(:redmine, [:id]))
      end
      def after_job(back_queue, job)
          job.update(accomplished: true)
      end
    end
  end
end
