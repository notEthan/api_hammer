require 'faraday'
require 'term/ansicolor'
require 'json'
require 'strscan'

module ApiHammer
  module Faraday
    class Request
      def initialize(request_env, response_env)
        @request_env = request_env
        @response_env = response_env
      end

      attr_reader :request_env
      attr_reader :response_env

      # deal with the vagaries of getting the response body in a form which JSON 
      # gem will not cry about generating 
      def response_body
        instance_variable_defined?(:@response_body) ? @response_body : @response_body = catch(:response_body) do
          unless response_env.body.is_a?(String)
            begin
              # if the response body is not a string, but JSON doesn't complain 
              # about dumping whatever it is, go ahead and use it
              JSON.generate([response_env.body])
              throw :response_body, response_env.body
            rescue
              # otherwise return nil - don't know what to do with whatever this object is 
              throw :response_body, nil
            end
          end

          # first try to change the string's encoding per the Content-Type header 
          content_type = response_env.response_headers['Content-Type']
          response_body = response_env.body.dup
          unless response_body.valid_encoding?
            # I think this always comes in as ASCII-8BIT anyway so may never get here. hopefully.
            response_body.force_encoding('ASCII-8BIT')
          end

          content_type_attrs = ContentTypeAttrs.new(content_type)
          if content_type_attrs.parsed?
            charset = content_type_attrs['charset'].first
            if charset && Encoding.list.any? { |enc| enc.to_s.downcase == charset.downcase }
              if response_body.dup.force_encoding(charset).valid_encoding?
                response_body.force_encoding(charset)
              else
                # I guess just ignore the specified encoding if the result is not valid. fall back to 
                # something else below.
              end
            end
          end
          begin
            JSON.generate([response_body])
          rescue Encoding::UndefinedConversionError
            # if updating by content-type didn't do it, try UTF8 since JSON wants that - but only 
            # if it seems to be valid utf8. 
            # don't try utf8 if the response content-type indicated something else. 
            try_utf8 = !(content_type_attrs && content_type_attrs.parsed? && content_type_attrs['charset'].any?)
            if try_utf8 && response_body.dup.force_encoding('UTF-8').valid_encoding?
              response_body.force_encoding('UTF-8')
            else
              # I'm not sure if there is a way in this situation to get JSON gem to generate the 
              # string correctly. fall back to an array of codepoints I guess? this is a weird 
              # solution but the best I've got for now. 
              response_body = response_body.codepoints.to_a
            end
          end
          response_body
        end
      end
    end

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

          request = ApiHammer::Faraday::Request.new(request_env, response_env)

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

          filtered_request_body = request_body.dup if request_body
          filtered_response_body = request.response_body.dup if request.response_body

          if @options[:filter_keys]
            body_info = [['request', filtered_request_body, request_env.request_headers], ['response', filtered_response_body, response_env.response_headers]]
            body_info.map do |(role, body, headers)|
              if body
                parsed_body = ApiHammer::ParsedBody.new(body, headers['Content-Type'])
                body.replace(parsed_body.filtered_body(@options.slice(:filter_keys)))
              end
            end
          end

          data = {
            'request_role' => 'client',
            'request' => {
              'method' => request_env[:method],
              'uri' => request_env[:url].normalize.to_s,
              'headers' => request_env.request_headers,
              'body' => (filtered_request_body if ContentTypeAttrs.new(request_env.request_headers['Content-Type']).text?),
            }.reject{|k,v| v.nil? },
            'response' => {
              'status' => response_env.status.to_s,
              'headers' => response_env.response_headers,
              'body' => (filtered_response_body if ContentTypeAttrs.new(response_env.response_headers['Content-Type']).text?),
            }.reject{|k,v| v.nil? },
            'processing' => {
              'began_at' => began_at.utc.to_f,
              'duration' => now - began_at,
              'activesupport_tagged_logging_tags' => @log_tags,
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
