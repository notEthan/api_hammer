require 'api_hammer/sinatra/halt'

module ApiHammer
  module Sinatra
    def self.included(klass)
      (@on_included || []).each do |included_proc|
        included_proc.call(klass)
      end
    end

    # override Sinatra::Base#route_missing
    def route_missing
      halt_error(404, {'route' => [I18n.t('app.errors.request.route_404', :method => env['REQUEST_METHOD'], :path => env['PATH_INFO'])]})
    end

    include ApiHammer::Sinatra::Halt

    unless instance_variables.any? { |iv| iv.to_s == '@supported_media_types_included' }
      @supported_media_types_included = proc do |klass|
        klass.define_singleton_method(:supported_media_types=) do |supported_media_types|
          @supported_media_types = supported_media_types
        end
        klass.define_singleton_method(:supported_media_types) do
          @supported_media_types
        end
      end
      (@on_included ||= Set.new) << @supported_media_types_included
    end

    def supported_media_types
      self.class.supported_media_types
    end

    # finds the best match (highest q) for those supported_media_types indicated as acceptable by the Accept header. 
    #
    # If the Accept header is not present, assumes that any supported media type is acceptable, and returns the first 
    # one.
    #
    # if the :halt_if_unacceptable option is true and no supported media type is acceptable, this halts with 406. 
    #
    # if the :halt_if_unacceptable option is false (or omitted) and no supported media type is acceptable, this 
    # returns the first supported media type. 
    def response_media_type(options={})
      options = {:halt_if_unacceptable => false}.merge(options)
      accept = env['HTTP_ACCEPT']
      if accept =~ /\S/
        begin
          best_media_type = env['rack-accept.request'].best_media_type(supported_media_types)
        rescue RuntimeError => e
          # TODO: this is a crappy way to recognize this exception 
          raise unless e.message =~ /Invalid header value/
        end
        if best_media_type
          best_media_type
        else
          if options[:halt_if_unacceptable]
            logger.error "received Accept header of #{accept.inspect}; halting with 406"
            halt_error(406, {'Accept' => [I18n.t('app.errors.request.accept', :accept => accept, :supported_media_types => supported_media_types.join(', '))]})
          else
            supported_media_types.first
          end
        end
      else
        supported_media_types.first
      end
    end

    def check_accept
      response_media_type(:halt_if_unacceptable => true)
    end

    # returns a rack response with the given object encoded in the appropriate format for the requests. 
    #
    # arguments are in the order of what tends to vary most frequently 
    # rather than rack's way, so headers come last 
    def format_response(status, body_object, headers={})
      body = case response_media_type
      when 'application/json'
        JSON.pretty_generate(body_object)
      else
        # :nocov:
        raise NotImplementedError, "unsupported response media type #{response_media_type}"
        # :nocov:
      end
      [status, headers.merge({'Content-Type' => response_media_type}), [body]]
    end

    # reads the request body 
    def request_body
      # rewind in case anything in the past has left this un-rewound 
      request.body.rewind
      request.body.read.tap do
        # rewind in case anything in the future expects this to have been left rewound 
        request.body.rewind
      end
    end

    # returns the parsed contents of the request body. 
    #
    # checks the Content-Type of the request, and unless it's supported (or omitted - in which case assumed to be the
    # first supported media type), halts with 415. 
    #
    # if the body is not parseable, then halts with 400. 
    def parsed_body
      request_media_type = request.media_type
      unless request_media_type =~ /\S/
        fallback = true
        request_media_type = supported_media_types.first
      end
      case request_media_type
      when 'application/json'
        begin
          return JSON.parse(request_body)
        rescue JSON::ParserError
          t_key = fallback ? 'app.errors.request.body_parse_fallback_json' : 'app.errors.request.body_parse_indicated_json'
          errors = {'json' => [I18n.t(t_key, :error_class => $!.class, :error_message => $!.message, :supported_media_types => supported_media_types.join(', '))]}
          halt_error(400, errors)
        end
      else
        if supported_media_types.include?(request_media_type)
          # :nocov:
          raise NotImplementedError, "handling request body with media type #{request_media_type} not implemented"
          # :nocov:
        end
        logger.error "received Content-Type of #{request.content_type.inspect}; halting with 415"
        errors = {'Content-Type' => [I18n.t('app.errors.request.content_type', :content_type => request.content_type, :supported_media_types => supported_media_types.join(', '))]}
        halt_error(415, errors)
      end
    end
  end
end
