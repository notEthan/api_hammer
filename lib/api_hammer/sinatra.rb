require 'api_hammer/sinatra/halt'
begin
  require 'rack/accept'
rescue LoadError => e
  raise e.class, e.message + "\nPlease `gem install rack_accept` or add rack_accept to your Gemfile", e.backtrace
end

module ApiHammer
  module Sinatra
    def self.included(klass)
      (@on_included || []).each do |included_proc|
        included_proc.call(klass)
      end
    end

    unless instance_variable_defined?(:@sinatra_included_defined)
      @sinatra_included_defined = true
      (@on_included ||= Set.new) << proc do |klass|
        # set up self.supported_media_types
        klass.define_singleton_method(:supported_media_types=) do |supported_media_types|
          @supported_media_types = supported_media_types
        end
        klass.define_singleton_method(:supported_media_types) do
          @supported_media_types
        end

        # causes a Rack::Lint middleware to be inserted before and after the given middleware to be used 
        klass.define_singleton_method(:use_with_lint) do |middleware, *args, &block|
          if (development? || test?) && (@middleware.empty? || @middleware.last.first != Rack::Lint)
            use Rack::Lint
          end
          use middleware, *args, &block
          use Rack::Lint if development? || test?
        end
      end
    end

    # override Sinatra::Base#route_missing
    def route_missing
      message = I18n.t('app.errors.request.route_404',
        :default => "Not a known route: %{method} %{path}",
        :method => env['REQUEST_METHOD'], :path => env['PATH_INFO']
      )
      halt_error(404, {'route' => [message]})
    end

    include ApiHammer::Sinatra::Halt

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
      env = options[:env] || (respond_to?(:env) ? self.env : raise(ArgumentError, "must pass env"))
      accept = env['HTTP_ACCEPT']
      if accept =~ /\S/
        begin
          best_media_type = Rack::Accept::Request.new(env).best_media_type(supported_media_types)
        rescue RuntimeError => e
          # TODO: this is a crappy way to recognize this exception 
          raise unless e.message =~ /Invalid header value/
        end
        if best_media_type
          best_media_type
        else
          if options[:halt_if_unacceptable]
            logger.error "received Accept header of #{accept.inspect}; halting with 406"
            message = I18n.t('app.errors.request.accept',
              :default => "The request indicated that no supported media type is acceptable. Supported media types are: %{supported_media_types}. The request specified Accept: %{accept}",
              :accept => accept,
              :supported_media_types => supported_media_types.join(', ')
            )
            halt_error(406, {'Accept' => [message]})
          else
            supported_media_types.first
          end
        end
      elsif supported_media_types && supported_media_types.any?
        supported_media_types.first
      else
        raise "No media types are defined. Please set supported_media_types."
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
      if status == 204
        body = ''
      else
        body = case response_media_type
        when 'application/json'
          JSON.pretty_generate(body_object)
        else
          # :nocov:
          raise NotImplementedError, "unsupported response media type #{response_media_type}"
          # :nocov:
        end
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
          if fallback
            t_key = 'app.errors.request.body_parse_fallback_json'
            default = "Error encountered attempting to parse the request body. No Content-Type was specified and parsing as JSON failed. Supported media types are %{supported_media_types}. JSON parser error: %{error_class}: %{error_message}"
          else
            t_key = 'app.errors.request.body_parse_indicated_json'
            default = "Error encountered attempting to parse the JSON request body: %{error_class}: %{error_message}"
          end
          message = I18n.t(t_key,
            :default => default,
            :error_class => $!.class,
            :error_message => $!.message,
            :supported_media_types => supported_media_types.join(', ')
          )
          errors = {'json' => [message]}
          halt_error(400, errors)
        end
      else
        if supported_media_types.include?(request_media_type)
          # :nocov:
          raise NotImplementedError, "handling request body with media type #{request_media_type} not implemented"
          # :nocov:
        end
        logger.error "received Content-Type of #{request.content_type.inspect}; halting with 415"
        message = I18n.t('app.errors.request.content_type',
          :default => "Unsupported Content-Type of %{content_type} given for the request body. Supported media types are %{supported_media_types}",
          :content_type => request.content_type,
          :supported_media_types => supported_media_types.join(', ')
        )
        errors = {'Content-Type' => [message]}
        halt_error(415, errors)
      end
    end

    # for methods where parameters which are required in the path may also be specified in the 
    # body, this takes the path_params and the body object and ensures that they are consistent 
    # any place they are specified in the body.
    def check_params_and_object_consistent(path_params, object)
      errors = {}
      path_params.each do |(k, v)|
        if object.key?(k) && object[k] != v
          errors[k] = [I18n.t('app.errors.inconsistent_uri_and_entity',
            :key => k,
            :uri_value => v,
            :entity_value => object[k],
            :default => "Inconsistent data given in the request URI and request entity: %{key} was specified as %{uri_value} in the URI but %{entity_value} in the entity",
          )]
        end
      end
      if errors.any?
        halt_error(422, errors)
      end
    end
  end
end
