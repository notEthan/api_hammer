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
      @request_body = env["rack.input"].read
      env["rack.input"].rewind

      log_tags = Thread.current[:activesupport_tagged_logging_tags]
      @log_tags = log_tags.dup if log_tags

      status, headers, body = @app.call(env)
      headers = ::Rack::Utils::HeaderHash.new(headers)
      body_proxy = ::Rack::BodyProxy.new(body) { log(env, status, headers, began_at, body) }
      [status, headers, body_proxy]
    end

    def log(env, status, headers, began_at, body)
      now = Time.now

      request = Rack::Request.new(env)
      response = Rack::Response.new('', status, headers)

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
      data = {
        'request' => {
          'method' => request.request_method,
          'uri' => request_uri.normalize.to_s,
          'length' => request.content_length,
          'Content-Type' => request.content_type,
          'remote_addr' => env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"],
          'User-Agent' => request.user_agent,
          'body' => @request_body,
          # these come from the OAuthenticator gem/middleware 
          'oauth.authenticated' => env['oauth.authenticated'],
          'oauth.consumer_key' => env['oauth.consumer_key'],
          'oauth.token' => env['oauth.token'],
          # airbrake
          'airbrake.error_id' => env['airbrake.error_id'],
        }.reject{|k,v| v.nil? },
        'response' => {
          'status' => status,
          'length' => headers['Content-Length'] || body.to_enum.map(&::Rack::Utils.method(:bytesize)).inject(0, &:+),
          'Location' => response.location,
          'Content-Type' => response.content_type,
        }.reject{|k,v| v.nil? },
        'processing' => {
          'began_at' => began_at.utc.to_i,
          'duration' => now - began_at,
          'activesupport_tagged_logging_tags' => @log_tags,
        }.merge(env['request_logger.info'] || {}).merge(Thread.current['request_logger.info'] || {}).reject{|k,v| v.nil? },
      }
      Thread.current['request_logger.info'] = nil
      json_data = JSON.dump(data)
      dolog = proc do
        @logger.info "#{status_s} : #{bold(intense_cyan(request.request_method))} #{intense_cyan(request_uri.normalize)}"
        @logger.info json_data
      end
      # do the logging with tags that applied to the request if appropriate 
      if @logger.respond_to?(:tagged) && @log_tags
        @logger.tagged(@log_tags, &dolog)
      else
        dolog.call
      end
    end
  end
end
