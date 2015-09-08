module Cacas::Custodians::Redmine::RecruitEmployeeSaga
  class RecruitedEmployeeJob < Cacas::Job
    extend Cacas::EventConfig
    require 'rest_client'
    require 'json'

    class << self

      def run job
        Cacas::JobProcessor.logger.info "RedmineCustodian processing #{job.inspect}"
        ret_proc = Proc.new {|resp_body, req, res| [resp_body, res]}
        opts = config[:rest_client_opts].merge({headers: {content_type: :json, accept: :json}})
        site = RestClient::Resource.new(config[:redmine_base_url], opts)
        user_atts = {firstname: job.data['user__name'],
                     lastname: job.data['user__surname'],
                     login: job.data['user__redmine_login'],
                     password: 'marilyn1',
                     mail: job.data['user__redmine_mail']}
        Cacas::JobProcessor.logger.debug  "job.data['user__redmine_mail'] #{job.data['user__redmine_mail']} user_atts #{user_atts}"
        res, ro = site['users.json'].post({user: user_atts}.to_json, &ret_proc)
        job_creds = {custodian: job.custodian, event: job.event, event_id: job.event_id}
        if ro.code == "201"
          rm_data = JSON::load res #, symbolize_names: true
          CacasBackQueue.create_or_update job_creds.merge(accomplished: true,
                                          data: {user__redmine_id: rm_data['user']['id'],
                                                 user__id: job.data['user__id']})
        else
          CacasBackQueue.create_or_update job_creds.merge(accomplished: false,
                                                data: {http_status: ro.code,
                                                       res: res,
                                                       job_data: job.data,
                                                       user_atts: user_atts})
        end
      end
    end
  end
end
