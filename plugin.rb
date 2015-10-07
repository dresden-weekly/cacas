class PluginMethods
    def create_job e, creds
      JobQueue.create event: e.event, event_id: e.id, data: creds
    end
end

class Event
  def find_by_ceid ceid
    find ceid.split('-').first.to_i
  end
end


class DovecotPlugin < Plugin

  handle :RecruitedEmployee do |e|

    e.data['companies'].each do |company|

      command :CreateEmployeeEmailAddress, name: e.data['name'],
                                           surname: e.data['surname'],
                                           company: company
    end
  end

  handle :CreatedEmployeeEmailAddress do |e|

    Event.where(event: 'AssociatedCompanyEmailServer')
      .select {|o| o.data['companies'].include? e.data['company']}
      .each do |o|
        command :AddEmailAddressToServer, server: e.data['server'],
                                          email: "#{o.id}-1",
                                          address: e.data['address']
      end
  end

  handle :AddedEmailAddressToServer do |e|

    ip = Event.find_by_ceid(e.data['server']).data['ip']
    address = Event.find_by_ceid(e.data['email']).data['address']

    create_job e, ip: ip, address: address, path: e.data['path']

  end

  handle :AddedEmailServerInstance do |e|

    create_job e, ip: e.data['ip']

  end

  handle :AssociatedCompanyEmailServer do |e|

    Event.where(event: 'CreatedEmployeeEmailAddress')
      .select {|o| o.data['company'] == e.data['company']}
      .each do |o|
        command :AddEmailAddressToServer, server: e.data['server'],
                                          email: "#{o.id}-1"
      end
  end
end

class AddEmailAddressToServer # saga

  acts_as_saga do |saga|
    server = saga.handles :AssociatedCompanyEmailServer
    address = saga.handles :CreatedEmployeeEmailAddress
    saga.where(server.company == address.company)
    result = saga.result :AddedEmailAddressToServer do |instance|
      job.create new ... do |response|
        instance.finish(path: response.path, id: response.id)
      end
    end
    saga.where(result.server == server.oid)
    saga.where(result.email == address.oid)
  end
end

#                ==
#        .               .
# :result :server :server :oid


class CreatedEmployeeRedmineAccount < Saga

  acts_as_saga do |saga|
    server = saga.trigger :AddedRedmineServerInstance
    employee = saga.trigger :RecruitedEmployee
    email = saga.trigger :CreatedEmployeeEmailAddress
    saga.where(server.company == address.company)
    # ...
  end
end
