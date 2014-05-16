require 'api_hammer'
require 'active_support/log_subscriber'

require 'rails/rack/log_tailer'
# fix up this class to tail the log when the body is closed rather than when its own #call is done. 
module Rails
  module Rack
    class LogTailer
      def call(env)
        status, headers, body = @app.call(env)
        body_proxy = ::Rack::BodyProxy.new(body) { tail! }
        [status, headers, body_proxy]
      end
    end
  end
end

module ApiHammer
  class RequestLogSubscriber < ActiveSupport::LogSubscriber
    def process_action(event)
      if event.payload[:request]
        info = (event.payload[:request].env['request_logger.info'] ||= {})
      else
        # if an exception occurs in the action, append_info_to_payload isn't called and event.payload[:request] 
        # doesn't get set. fall back to use Thread.current.
        info = (Thread.current['request_logger.info'] ||= {})
      end
      info.update(event.payload.slice(:controller, :action, :exception, :format, :formats, :view_runtime, :db_runtime))
      info.update(:transaction_id => event.transaction_id)
      info.update(event.payload['request_logger.info']) if event.payload['request_logger.info']
    end
  end
end

module AddRequestToPayload
  def append_info_to_payload(payload)
    super
    payload[:request] = request
  end
end

module ApiHammer
  class RailsRequestLogging < ::Rails::Railtie
    initializer :api_hammer_request_logging do |app|
      # use the bits we want from Lograge.setup, disabling existing active* log things. 
      # but don't actually enable lograge. 
      require 'lograge'
      require 'lograge/rails_ext/rack/logger'
      app.config.action_dispatch.rack_cache[:verbose] = false if app.config.action_dispatch.rack_cache
      Lograge.remove_existing_log_subscriptions

      ApiHammer::RequestLogSubscriber.attach_to :action_controller

      app.config.middleware.insert_before(::Rails::Rack::Logger, ApiHammer::RequestLogger, ::Rails.logger)

      ActionController::Base.send(:include, AddRequestToPayload)
    end
  end
end
