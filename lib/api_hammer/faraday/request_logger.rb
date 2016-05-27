require 'faraday'
require 'term/ansicolor'
require 'json'
require 'strscan'

module ApiHammer
  module Faraday
    # Faraday middleware for logging.
    #
    # logs two lines:
    #
    # - an info line, colored prettily to show a brief summary of the request and response
    # - a debug line of json to record all relevant info. this is a lot of stuff jammed into one line, not 
    #   pretty, but informative.
    #
    # options:
    # - :filter_keys defines keys whose values will be filtered out of the logging 
    class RequestLogger < ::Faraday::Middleware
      include Term::ANSIColor

      def initialize(app, logger, options={})
        @app = app
        @logger = logger
        @options = options
      end

      def call(request_env)
        began_at = Time.now

        log_tags = Thread.current[:activesupport_tagged_logging_tags]
        saved_log_tags = log_tags.dup if log_tags && log_tags.any?

        request_body = request_env[:body].dup if request_env[:body]

        @app.call(request_env).on_complete do |response_env|
          now = Time.now

          status_color = case response_env.status.to_i
          when 200..299
            :intense_green
          when 400..499
            :intense_yellow
          when 500..599
            :intense_red
          else
            :white
          end
          status_s = bold(send(status_color, response_env.status.to_s))

          bodies = [
            ['request', request_body, request_env.request_headers],
            ['response', response_env.body, response_env.response_headers]
          ].map do |(role, body, headers)|
            {role => Body.new(body, headers['Content-Type'])}
          end.inject({}, &:update)

          if @options[:filter_keys]
            bodies = bodies.map do |(role, body)|
              {role => body.filtered(:filter_keys => @options[:filter_keys])}
            end.inject({}, &:update)
          end

          data = {
            'request_role' => 'client',
            'request' => {
              'method' => request_env[:method],
              'uri' => request_env[:url].normalize.to_s,
              'headers' => request_env.request_headers,
              'body' => (bodies['request'].jsonifiable.body if bodies['request'].content_type_attrs.text?),
            }.reject{|k,v| v.nil? },
            'response' => {
              'status' => response_env.status.to_s,
              'headers' => response_env.response_headers,
              'body' => (bodies['response'].jsonifiable.body if bodies['response'].content_type_attrs.text?),
            }.reject{|k,v| v.nil? },
            'processing' => {
              'began_at' => began_at.utc.to_f,
              'duration' => now - began_at,
              'activesupport_tagged_logging_tags' => log_tags,
            }.reject{|k,v| v.nil? },
          }

          json_data = JSON.generate(data)
          dolog = proc do
            now_s = now.strftime('%Y-%m-%d %H:%M:%S %Z')
            @logger.info "#{bold(intense_magenta('>'))} #{status_s} : #{bold(intense_magenta(request_env[:method].to_s.upcase))} #{intense_magenta(request_env[:url].normalize.to_s)} @ #{intense_magenta(now_s)}"
            @logger.info json_data
          end

          # reapply log tags from the request if they are not applied 
          if @logger.respond_to?(:tagged) && saved_log_tags && Thread.current[:activesupport_tagged_logging_tags] != saved_log_tags
            @logger.tagged(saved_log_tags, &dolog)
          else
            dolog.call
          end
        end
      end
    end
  end
end
