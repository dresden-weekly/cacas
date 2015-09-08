class Cacas::Custodians::Redmine::RecruitEmployeeSaga < Cacas::Saga

  default_finder user_id: :id

  set_finder_for :abused_employee, some_criterion: :my_criterion, different: :other

  set_finder_for :dropped_employee do |event|

    where(my_criterion: event.data[:some_criterion]).first || where(other: event.data[:different]).first

  end

  on_event :recruited_employee do |event|
    # JobQueue.create(custodian: :redmine, event: event.event, event_id: event.id, data: command.adapted(:redmine, [:surname, :name]))
  end

  after_job :recruited_employee do |back_queue, job|
    # ActiveRecord::Base.transaction do
    #   succ = User.find(back_queue.data['user__id']).update(redmine_id: back_queue.data['user__redmine_id'])
    #   job.update(accomplished: true) if succ
    # end
  end
end
