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
      if event.payload[:request_env]
        info = (event.payload[:request_env]['request_logger.info'] ||= {})
      else
        # if an exception occurs in the action, append_info_to_payload isn't called and 
        # event.payload[:request_env] doesn't get set. fall back to use Thread.current.
        info = (Thread.current['request_logger.info'] ||= {})
      end
      info.update(event.payload.slice(:controller, :action, :exception, :format, :formats, :view_runtime, :db_runtime))
      info.update(:transaction_id => event.transaction_id)
      info.update(event.payload['request_logger.info']) if event.payload['request_logger.info']
      # if there is an exception, ActiveSupport saves the class and message but not backtrace. but this 
      # gets called from an ensure block, so $! is set - retrieve the backtrace from that.
      if $!
        # this may be paranoid - it should always be the case that what gets set in :exception is the 
        # same as the current error, but just in case it's not, we'll put the current error somewhere else
        if info[:exception] == [$!.class.to_s, $!.message]
          info[:exception] += [$!.backtrace]
        else
          info[:current_exception] = [$!.class.to_s, $!.message, $!.backtrace]
        end
      end
    end
  end
end

module AddRequestToPayload
  def append_info_to_payload(payload)
    super
    payload[:request_env] = request.env
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

      options = app.config.respond_to?(:api_hammer_request_logging_options) ? app.config.api_hammer_request_logging_options : {}
      app.config.middleware.insert_after(::Rails::Rack::Logger, ApiHammer::RequestLogger, ::Rails.logger, options)

      ActionController::Base.send(:include, AddRequestToPayload)
    end
  end
end
