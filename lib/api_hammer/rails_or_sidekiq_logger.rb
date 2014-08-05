module ApiHammer
  # switch a logger between Rails.logger and sidekiq's logger 
  #
  #     Sidekiq.configure_server do |config|
  #       ...
  #       
  #       config.server_middleware do |chain|
  #         chain.add ApiHammer::RailsOrSidekiqLoggerMiddleware
  #       end
  #     end
  class RailsOrSidekiqLoggerMiddleware
    def call(worker, msg, queue, &block)
      ApiHammer::RailsOrSidekiqLogger.with_logger(worker.logger, &block)
    end
  end

  # include in a class to define #logger which will switch between Sidekiq and Rails 
  # using RailsOrSidekiqLoggerMiddleware
  #
  #     class Foo
  #       include ApiHammer::RailsOrSidekiqLogger
  #     end
  #
  module RailsOrSidekiqLogger
    LOGGER_KEY = 'api_hammer_rails_or_sidekiq_logger'
    def with_logger(logger)
      orig_logger = Thread.current[LOGGER_KEY]
      begin
        Thread.current[LOGGER_KEY] = logger
        yield
      ensure
        Thread.current[LOGGER_KEY] = orig_logger
      end
    end

    def logger
      logger = Thread.current[LOGGER_KEY] || ::Rails.logger
      logger.respond_to?(:tagged) ? logger : ::ActiveSupport::TaggedLogging.new(logger)
    end

    extend self
  end
end
