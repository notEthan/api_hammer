require 'rack'
require 'term/ansicolor'
require 'json'
require 'addressable/uri'

module ApiHammer
  # Rack middleware for logging. much like Rack::CommonLogger but with a log message that isn't an unreadable 
  # mess of dashes and unlabeled numbers. 
  #
  # two lines:
  #
  # - an info line, colored prettily to show a brief summary of the request and response
  # - a debug line of json to record all relevant info. this is a lot of stuff jammed into one line, not 
  #   pretty, but informative.
  class RequestLogger < Rack::CommonLogger
    include Term::ANSIColor

    LARGE_BODY_SIZE = 4096

    # options
    # - :logger
    # - :filter_keys
    def initialize(app, logger, options={})
      @options = options
      super(app, logger)
    end

    def call(env)
      began_at = Time.now

      # this is closed after the app is called, so read it before 
      env["rack.input"].rewind
      request_body = env["rack.input"].read
      env["rack.input"].rewind

      log_tags = Thread.current[:activesupport_tagged_logging_tags]
      log_tags = log_tags.dup if log_tags && log_tags.any?

      request = Rack::Request.new(env)
      request_uri = Addressable::URI.new(
        :scheme => request.scheme,
        :host => request.host,
        :port => request.port,
        :path => request.path,
        :query => (request.query_string unless request.query_string.empty?)
      )

      status, response_headers, response_body = @app.call(env)
      response_headers = ::Rack::Utils::HeaderHash.new(response_headers)
      body_proxy = ::Rack::BodyProxy.new(response_body) do
        log(env, request_uri, request_body, status, response_headers, response_body, began_at, log_tags)
      end
      [status, response_headers, body_proxy]
    end

    def log(env, request_uri, request_body, status, response_headers, response_body, began_at, log_tags)
      now = Time.now

      request = Rack::Request.new(env)
      response = Rack::Response.new('', status, response_headers)

      status_color = case status.to_i
      when 200..299
        :intense_green
      when 400..499
        :intense_yellow
      when 500..599
        :intense_red
      else
        :white
      end
      status_s = bold(send(status_color, status.to_s))

      request_headers = env.map do |(key, value)|
        http_match = key.match(/\AHTTP_/)
        if http_match
          name = http_match.post_match.downcase
          {name => value}
        else
          name = %w(content_type content_length).detect { |name| name.downcase == key.downcase }
          if name
            {name => value}
          end
        end
      end.compact.inject({}, &:update)

      data = {
        'request_role' => 'server',
        'request' => {
          'method' => request.request_method,
          'uri' => request_uri.normalize.to_s,
          'headers' => request_headers,
          'remote_addr' => env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"],
          # these come from the OAuthenticator gem/middleware 
          'oauth.authenticated' => env['oauth.authenticated'],
          'oauth.consumer_key' => env['oauth.consumer_key'],
          'oauth.token' => env['oauth.token'],
          # airbrake
          'airbrake.error_id' => env['airbrake.error_id'],
        }.reject { |k,v| v.nil? },
        'response' => {
          'status' => status.to_s,
          'headers' => response_headers,
          'length' => response_headers['Content-Length'] || response_body.to_enum.map(&::Rack::Utils.method(:bytesize)).inject(0, &:+),
        }.reject { |k,v| v.nil? },
        'processing' => {
          'began_at' => began_at.utc.to_f,
          'duration' => now - began_at,
          'activesupport_tagged_logging_tags' => log_tags,
        }.merge(env['request_logger.info'] || {}).merge(Thread.current['request_logger.info'] || {}).reject { |k,v| v.nil? },
      }
      response_body_string = response_body.to_enum.to_a.join('')
      body_info = [['request', request_body, request.content_type], ['response', response_body_string, response.content_type]]
      body_info.map do |(role, body, content_type)|
        parsed_body = ApiHammer::ParsedBody.new(body, content_type)
        if (400..599).include?(status.to_i) || body.size < LARGE_BODY_SIZE
          # log bodies if they are not large, or if there was an error (either client or server) 
          data[role]['body'] = parsed_body.filtered_body(@options.reject { |k,v| ![:filter_keys].include?(k) })
        else
          # otherwise, log id and uuid fields 
          body_object = parsed_body.object
          sep = /(?:\b|\W|_)/
          hash_ids = proc do |hash|
            hash.reject { |key, value| !(key =~ /#{sep}([ug]u)?id#{sep}/ && value.is_a?(String)) }
          end
          if body_object.is_a?(Hash)
            body_ids = hash_ids.call(body_object)
          elsif body_object.is_a?(Array) && body_object.all? { |e| e.is_a?(Hash) }
            body_ids = body_object.map(&hash_ids)
          end

          data[role]['body_ids'] = body_ids if body_ids && body_ids.any?
        end
      end
      Thread.current['request_logger.info'] = nil
      json_data = JSON.dump(data)
      dolog = proc do
        now_s = now.strftime('%Y-%m-%d %H:%M:%S %Z')
        @logger.info "#{bold(intense_cyan('<'))} #{status_s} : #{bold(intense_cyan(request.request_method))} #{intense_cyan(request_uri.normalize)} @ #{intense_cyan(now_s)}"
        @logger.info json_data
      end
      # do the logging with tags that applied to the request if appropriate 
      if @logger.respond_to?(:tagged) && log_tags
        @logger.tagged(log_tags, &dolog)
      else
        dolog.call
      end
    end
  end
end
