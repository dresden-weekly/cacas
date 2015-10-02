class PluginMethods
  # siehe plugin.rb
end
# class Hash
#   def &(list)
#     Hash[*(self.keys & list).map {|p| [p, self[p]]}.flatten]
#   end
# end
class Event
  # siehe plugin.rb
  # def lookup_properties ceid, updating_event, props
  #   origin = find ceid.split('-').first.to_i
  #   current = where(event: updating_event)
  #     .oder(:id)
  #     .reduce(origin.data) {|orig, update| orig.update update.data}
  #   Hash[*props.map {|p| [p, current[p]]}.flatten]
  #   # current & props
  # end

end


class RedminePlugin < Plugin

  handle :CreatedEmployeeRedmineAccount do |e|

    name      = Event.find_by_ceid(e.data['employee']).data['name']
    surname   = Event.find_by_ceid(e.data['employee']).data['surname']
    email     = Event.find_by_ceid(e.data['email']).data['address']
    ip        = Event.find_by_ceid(e.data['server']).data['ip']
    create_job e, name: name,
                  surname: surname,
                  login: oh_lord_gimme_a_login(),
                  password: oh_lord_gimme_a_password(),
                  email: email
  end
end
