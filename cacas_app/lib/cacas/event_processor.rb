class Cacas::EventProcessor
  cattr_accessor :logger

  class << self

    def process_events
      logger.info "processing events in #{__FILE__}"
    end

    def process event

      Cacas::ADAPTERS.each do |adapter|
        logger.info "---------adapter.class.to_s #{adapter.to_s}"
          command = adapter.send cmd_name, command if adapter.respond_to? cmd_name
        # rescue
        #   logger.error "---------something went wrong in #{__FILE__}-----------"
        #   break
        # end
      end
    end
  end
end
