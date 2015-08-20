class Cacas::Adapters::Redmine::DismissedEmployeeJob < Cacas::Job
  extend Cacas::EventConfig
  require 'rest_client'
  require 'json'

  class << self

    def run job
      Cacas::JobProcessor.logger.info "RedmineAdapter processing #{job.inspect}"
      ret_proc = Proc.new {|resp_body, req, res| [resp_body, res]}
      opts = config[:rest_client_opts].merge({headers: {content_type: :json, accept: :json}})
      site = RestClient::Resource.new(config[:redmine_base_url], opts)
      # Cacas::JobProcessor.logger.debug  "job.data['user__redmine_mail'] #{job.data['user__redmine_mail']} user_atts #{user_atts}"
      res, ro = site["users/#{job.data['user__redmine_id']}.json"].delete &ret_proc
      job_creds = {adapter: job.adapter, event: job.event, event_id: job.event_id}
      if ro.code == "200"
        CacasBackQueue.create_or_update job_creds.merge(accomplished: true)
      else
        CacasBackQueue.create_or_update job_creds.merge(accomplished: false,
                                              data: {http_status: ro.code,
                                                     res: res,
                                                     job_data: job.data})
      end
    end
  end
end
