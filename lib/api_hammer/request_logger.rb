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

    def call(env)
      began_at = Time.now

      # this is closed after the app is called, so read it before 
      env["rack.input"].rewind
      request_body = env["rack.input"].read
      env["rack.input"].rewind

      log_tags = Thread.current[:activesupport_tagged_logging_tags]
      log_tags = log_tags.dup if log_tags && log_tags.any?

      status, response_headers, response_body = @app.call(env)
      response_headers = ::Rack::Utils::HeaderHash.new(response_headers)
      body_proxy = ::Rack::BodyProxy.new(response_body) do
        log(env, request_body, status, response_headers, response_body, began_at, log_tags)
      end
      [status, response_headers, body_proxy]
    end

    def log(env, request_body, status, response_headers, response_body, began_at, log_tags)
      now = Time.now

      request = Rack::Request.new(env)
      response = Rack::Response.new('', status, response_headers)

      request_uri = Addressable::URI.new(
        :scheme => request.scheme,
        :host => request.host,
        :port => request.port,
        :path => request.path,
        :query => (request.query_string unless request.query_string.empty?)
      )
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
        }.reject{|k,v| v.nil? },
        'response' => {
          'status' => status,
          'headers' => response_headers,
          'length' => response_headers['Content-Length'] || response_body.to_enum.map(&::Rack::Utils.method(:bytesize)).inject(0, &:+),
        }.reject{|k,v| v.nil? },
        'processing' => {
          'began_at' => began_at.utc.to_i,
          'duration' => now - began_at,
          'activesupport_tagged_logging_tags' => log_tags,
        }.merge(env['request_logger.info'] || {}).merge(Thread.current['request_logger.info'] || {}).reject{|k,v| v.nil? },
      }
      ids_from_body = proc do |body_string, content_type|
        media_type = ::Rack::Request.new({'CONTENT_TYPE' => content_type}).media_type
        body_object = begin
          if media_type == 'application/json'
            JSON.parse(body_string) rescue nil
          elsif media_type == 'application/x-www-form-urlencoded'
            CGI.parse(body_string).map { |k, vs| {k => vs.last} }.inject({}, &:update)
          end
        end
        if body_object.is_a?(Hash)
          sep = /(?:\b|\W|_)/
          body_object.reject { |key, value| !(key =~ /#{sep}([ug]u)?id#{sep}/ && value.is_a?(String)) }
        end
      end
      response_body_string = response_body.to_enum.to_a.join('')
      if (400..599).include?(status.to_i)
        # only log bodies if there was an error (either client or server) 
        data['request']['body'] = request_body
        data['response']['body'] = response_body_string
      else
        # otherwise, log id and uuid fields 
        request_body_ids = ids_from_body.call(request_body, request.content_type)
        data['request']['body_ids'] = request_body_ids if request_body_ids && request_body_ids.any?
        response_body_ids = ids_from_body.call(response_body_string, response.content_type)
        data['response']['body_ids'] = response_body_ids if response_body_ids && response_body_ids.any?
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
