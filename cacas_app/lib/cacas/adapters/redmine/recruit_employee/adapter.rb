class Cacas::Adapters::RecruitEmployee < CacasAdapter

  class << self
    def prepare_command(command)
      command.adapt(:redmine, [:login, :email, ...])
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
    def process_event(event)
      Jobs.create(:redmine, event.adapted(:login, :email).merge(event.attributes(:surname, :name)))
    end
    def after_job(event, job_result)
      User.find(event.id).update_adapter_attributes(:redmine, id: job_result[:id])
    end

    def create_new_user command
      Rails.logger.info "RedmineAdapter processing CreateNewUser for user #{command.inspect}"
      # puts job_details
      command
    end

    def created_new_user event
      Rails.logger.info "RedmineAdapter processing CreatedNewUser  #{event.inspect}"
      ret_proc = Proc.new {|resp_body, req, res| [resp_body, res]}
      opts = config[:rest_client_opts].merge({headers: {content_type: :json, accept: :json}})
      site = RestClient::Resource.new(config[:redmine_base_url], opts)
      user_atts = {firstname: event.user__firstname,
                   lastname: event.user__lastname,
                   login: event.user__username,
                   password: 'marilyn1',
                   mail: event.user__email}
      res, ro = site['users.json'].post({user: user_atts}.to_json, &ret_proc)
      if ro.code == "201"
        rm_data = JSON::decode res, symbolize_names: true
        Rails.logger.info "Redmine answered #{res.inspect}"
      end
    end
  end
end
