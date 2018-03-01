module ApiHammer
  module HaltMethods
    # halt and render the given errors in the body on the 'errors' key 
    def halt_error(status, errors, options = {})
      errors_as_json = errors.respond_to?(:as_json) ? errors.as_json : errors
      unless errors_as_json.is_a?(Hash)
        raise ArgumentError, "errors be an object representable in JSON as a Hash; got errors = #{errors.inspect}"
      end
      unless errors_as_json.keys.all? { |k| k.is_a?(String) || k.is_a?(Symbol) }
        raise ArgumentError, "errors keys must all be string or symbol; got errors = #{errors.inspect}"
      end
      unless errors_as_json.values.all? { |v| v.is_a?(Array) && v.all? { |e| e.is_a?(String) } }
        raise ArgumentError, "errors values must all be arrays of strings; got errors = #{errors.inspect}"
      end
      error_message = nil
      halt_options = options.reject do |k,v|
        (k.to_s == 'error_message').tap do |is_error_message|
          if is_error_message
            error_message = v
          end
        end
      end
      body = {'errors' => errors}
      error_message ||= begin
        error_values = errors.values.inject([], &:+)
        if error_values.size <= 1
          error_values.first
        else
          # sentencify with periods 
          error_values.map { |v| v =~ /\.\s*\z/ ? v : v + '.' }.join(' ')
        end
      end
      body['error_message'] = error_message if error_message
      if Object.const_defined?(:Rollbar) and status != 404 and Object.const_defined?(:DEBUG_4XX) and DEBUG_4XX['enabled']
        Rollbar.debug "Service halted with status #{status}", status: status, body: body, halt_options: halt_options
      end
      halt(status, body, halt_options)
    end

    # attempts to find and return the given model (an ActiveRecord::Base subclass) with the given attributes. 
    # halts with 404 (does not return) if that fails. options[:status] may specify a different status if that 
    # is required.
    #
    # e.g.:
    #
    #     find_or_halt(User, :email => 'user@example.com')
    #
    def find_or_halt(model, find_attrs, options={})
      options = {:status => 404}.merge(options)
      record = model.where(find_attrs).first
      unless record
        attributes = find_attrs.map { |attr, val| "#{attr}: #{val}" }.join(", ")
        model_name = model.table_name
        model_name = model_name.singularize if model_name.respond_to?(:singularize)
        message = I18n.t(:"errors.unknown_record_with_attributes", :default => "Unknown %{model_name}! %{attributes}",
          :model_name => model_name,
          :attributes => attributes
        )
        halt_error(options[:status], {model_name => [message]})
      end
      record
    end

    # halt with status 200 OK, responding with the given body object 
    def halt_ok(body, render_options = {})
      halt(200, body, render_options)
    end

    # halt with status 201 Created, responding with the given body object 
    def halt_created(body, render_options = {})
      halt(201, body, render_options)
    end

    # halt with status 202 Accepted, responding with the given body object 
    def halt_accepted(body, render_options = {})
      halt(202, body, render_options)
    end

    # halt with status 203 Non-Authoritative Information, responding with the given body object 
    def halt_non_authoritative_information(body, render_options = {})
      halt(203, body, render_options)
    end

    # halt with status 204 No Content
    def halt_no_content(render_options = {})
      halt(204, '', render_options)
    end

    # halt with status 205 Reset Content
    def halt_reset_content(render_options = {})
      halt(205, '', render_options)
    end

    # halt with status 206 Partial Content, responding with the given body object 
    def halt_partial_content(body, render_options = {})
      halt(206, body, render_options)
    end

    # halt with status 207 Multi-Status, responding with the given body object 
    def halt_multi_status(body, render_options = {})
      halt(207, body, render_options)
    end

    # halt with status 208 Already Reported, responding with the given body object 
    def halt_already_reported(body, render_options = {})
      halt(208, body, render_options)
    end

    # halt with status 226 IM Used, responding with the given body object 
    def halt_im_used(body, render_options = {})
      halt(226, body, render_options)
    end

    # halt with status 300 Multiple Choices, responding with the given body object 
    def halt_multiple_choices(body, render_options = {})
      halt(300, body, render_options)
    end

    # halt with status 301 Moved Permanently, responding with the given body object 
    def halt_moved_permanently(body, render_options = {})
      halt(301, body, render_options)
    end

    # halt with status 302 Found, responding with the given body object 
    def halt_found(body, render_options = {})
      halt(302, body, render_options)
    end

    # halt with status 303 See Other, responding with the given body object 
    def halt_see_other(body, render_options = {})
      halt(303, body, render_options)
    end

    # halt with status 304 Not Modified
    def halt_not_modified(render_options = {})
      halt(304, '', render_options)
    end

    # halt with status 305 Use Proxy, responding with the given body object 
    def halt_use_proxy(body, render_options = {})
      halt(305, body, render_options)
    end

    # halt with status 307 Temporary Redirect, responding with the given body object 
    def halt_temporary_redirect(body, render_options = {})
      halt(307, body, render_options)
    end

    # halt with status 308 Permanent Redirect, responding with the given body object 
    def halt_permanent_redirect(body, render_options = {})
      halt(308, body, render_options)
    end

    # halt with status 400 Bad Request, responding with the given errors object on the 'errors' key
    def halt_bad_request(errors, render_options = {})
      halt_error(400, errors, render_options)
    end

    # halt with status 401 Unauthorized, responding with the given errors object on the 'errors' key
    def halt_unauthorized(errors, render_options = {})
      halt_error(401, errors, render_options)
    end

    # halt with status 402 Payment Required, responding with the given errors object on the 'errors' key
    def halt_payment_required(errors, render_options = {})
      halt_error(402, errors, render_options)
    end

    # halt with status 403 Forbidden, responding with the given errors object on the 'errors' key
    def halt_forbidden(errors, render_options = {})
      halt_error(403, errors, render_options)
    end

    # halt with status 404 Not Found, responding with the given errors object on the 'errors' key
    def halt_not_found(errors, render_options = {})
      halt_error(404, errors, render_options)
    end

    # halt with status 405 Method Not Allowed, responding with the given errors object on the 'errors' key
    def halt_method_not_allowed(errors, render_options = {})
      halt_error(405, errors, render_options)
    end

    # halt with status 406 Not Acceptable, responding with the given errors object on the 'errors' key
    def halt_not_acceptable(errors, render_options = {})
      halt_error(406, errors, render_options)
    end

    # halt with status 407 Proxy Authentication Required, responding with the given errors object on the 'errors' key
    def halt_proxy_authentication_required(errors, render_options = {})
      halt_error(407, errors, render_options)
    end

    # halt with status 408 Request Timeout, responding with the given errors object on the 'errors' key
    def halt_request_timeout(errors, render_options = {})
      halt_error(408, errors, render_options)
    end

    # halt with status 409 Conflict, responding with the given errors object on the 'errors' key
    def halt_conflict(errors, render_options = {})
      halt_error(409, errors, render_options)
    end

    # halt with status 410 Gone, responding with the given errors object on the 'errors' key
    def halt_gone(errors, render_options = {})
      halt_error(410, errors, render_options)
    end

    # halt with status 411 Length Required, responding with the given errors object on the 'errors' key
    def halt_length_required(errors, render_options = {})
      halt_error(411, errors, render_options)
    end

    # halt with status 412 Precondition Failed, responding with the given errors object on the 'errors' key
    def halt_precondition_failed(errors, render_options = {})
      halt_error(412, errors, render_options)
    end

    # halt with status 413 Request Entity Too Large, responding with the given errors object on the 'errors' key
    def halt_request_entity_too_large(errors, render_options = {})
      halt_error(413, errors, render_options)
    end

    # halt with status 414 Request-URI Too Long, responding with the given errors object on the 'errors' key
    def halt_request_uri_too_long(errors, render_options = {})
      halt_error(414, errors, render_options)
    end

    # halt with status 415 Unsupported Media Type, responding with the given errors object on the 'errors' key
    def halt_unsupported_media_type(errors, render_options = {})
      halt_error(415, errors, render_options)
    end

    # halt with status 416 Requested Range Not Satisfiable, responding with the given errors object on the 'errors' key
    def halt_requested_range_not_satisfiable(errors, render_options = {})
      halt_error(416, errors, render_options)
    end

    # halt with status 417 Expectation Failed, responding with the given errors object on the 'errors' key
    def halt_expectation_failed(errors, render_options = {})
      halt_error(417, errors, render_options)
    end

    # halt with status 418 I'm a teapot, responding with the given errors object on the 'errors' key
    def halt_im_a_teapot(errors, render_options = {})
      halt_error(418, errors, render_options)
    end

    # halt with status 419 Authentication Timeout, responding with the given errors object on the 'errors' key
    def halt_authentication_timeout(errors, render_options = {})
      halt_error(419, errors, render_options)
    end

    # halt with status 422 Unprocessable Entity, responding with the given errors object on the 'errors' key
    def halt_unprocessable_entity(errors, render_options = {})
      halt_error(422, errors, render_options)
    end

    # halt with status 423 Locked, responding with the given errors object on the 'errors' key
    def halt_locked(errors, render_options = {})
      halt_error(423, errors, render_options)
    end

    # halt with status 424 Failed Dependency, responding with the given errors object on the 'errors' key
    def halt_failed_dependency(errors, render_options = {})
      halt_error(424, errors, render_options)
    end

    # halt with status 425 Unordered Collection, responding with the given errors object on the 'errors' key
    def halt_unordered_collection(errors, render_options = {})
      halt_error(425, errors, render_options)
    end

    # halt with status 426 Upgrade Required, responding with the given errors object on the 'errors' key
    def halt_upgrade_required(errors, render_options = {})
      halt_error(426, errors, render_options)
    end

    # halt with status 428 Precondition Required, responding with the given errors object on the 'errors' key
    def halt_precondition_required(errors, render_options = {})
      halt_error(428, errors, render_options)
    end

    # halt with status 429 Too Many Requests, responding with the given errors object on the 'errors' key
    def halt_too_many_requests(errors, render_options = {})
      halt_error(429, errors, render_options)
    end

    # halt with status 431 Request Header Fields Too Large, responding with the given errors object on the 'errors' key
    def halt_request_header_fields_too_large(errors, render_options = {})
      halt_error(431, errors, render_options)
    end

    # halt with status 444 No Response, responding with the given errors object on the 'errors' key
    def halt_no_response(errors, render_options = {})
      halt_error(444, errors, render_options)
    end

    # halt with status 451 Unavailable For Legal Reasons, responding with the given errors object on the 'errors' key
    def halt_unavailable_for_legal_reasons(errors, render_options = {})
      halt_error(451, errors, render_options)
    end

    # halt with status 451 Redirect, responding with the given errors object on the 'errors' key
    def halt_redirect(errors, render_options = {})
      halt_error(451, errors, render_options)
    end

    # halt with status 500 Internal Server Error, responding with the given errors object on the 'errors' key
    def halt_internal_server_error(errors, render_options = {})
      halt_error(500, errors, render_options)
    end

    # halt with status 501 Not Implemented, responding with the given errors object on the 'errors' key
    def halt_not_implemented(errors, render_options = {})
      halt_error(501, errors, render_options)
    end

    # halt with status 502 Bad Gateway, responding with the given errors object on the 'errors' key
    def halt_bad_gateway(errors, render_options = {})
      halt_error(502, errors, render_options)
    end

    # halt with status 503 Service Unavailable, responding with the given errors object on the 'errors' key
    def halt_service_unavailable(errors, render_options = {})
      halt_error(503, errors, render_options)
    end

    # halt with status 504 Gateway Timeout, responding with the given errors object on the 'errors' key
    def halt_gateway_timeout(errors, render_options = {})
      halt_error(504, errors, render_options)
    end

    # halt with status 505 HTTP Version Not Supported, responding with the given errors object on the 'errors' key
    def halt_http_version_not_supported(errors, render_options = {})
      halt_error(505, errors, render_options)
    end

    # halt with status 506 Variant Also Negotiates, responding with the given errors object on the 'errors' key
    def halt_variant_also_negotiates(errors, render_options = {})
      halt_error(506, errors, render_options)
    end

    # halt with status 507 Insufficient Storage, responding with the given errors object on the 'errors' key
    def halt_insufficient_storage(errors, render_options = {})
      halt_error(507, errors, render_options)
    end

    # halt with status 508 Loop Detected, responding with the given errors object on the 'errors' key
    def halt_loop_detected(errors, render_options = {})
      halt_error(508, errors, render_options)
    end

    # halt with status 509 Bandwidth Limit Exceeded, responding with the given errors object on the 'errors' key
    def halt_bandwidth_limit_exceeded(errors, render_options = {})
      halt_error(509, errors, render_options)
    end

    # halt with status 510 Not Extended, responding with the given errors object on the 'errors' key
    def halt_not_extended(errors, render_options = {})
      halt_error(510, errors, render_options)
    end

    # halt with status 511 Network Authentication Required, responding with the given errors object on the 'errors' key
    def halt_network_authentication_required(errors, render_options = {})
      halt_error(511, errors, render_options)
    end
=begin
# the above methods are generated with the following script

require 'nokogiri'
require 'faraday'
wpcodes = Nokogiri::HTML(Faraday.get('https://en.wikipedia.org/wiki/List_of_HTTP_status_codes').body)
dts = wpcodes.css('dt')
puts(dts.map do |dt|
  if dt.text =~ /\A\s*(\d+)\s+([a-z0-9 \-']+)/i
    status = $1.to_i
    name = $2.strip
    underscore = name.split(/[\s-]/).map{|word| word.downcase.gsub(/\W/, '') }.join('_')
    if ([100..199, 490..499, 520..599].map(&:to_a).inject([], &:+) + [306, 420, 440, 449, 450]).include?(status)
      # exclude these. 1xx isn't really a thing that makes sense at this level and the others are 
      # nonstandard or particular particular web servers or such 
      nil
    elsif [204, 205, 304].include?(status)
      # ones with no body
%Q(
  # halt with status #{status} #{name}
  def halt_#{underscore}(render_options = {})
    halt(#{status}, '', render_options)
  end
)
    elsif (400..599).include?(status)
      # body goes on an errors object
%Q(
  # halt with status #{status} #{name}, responding with the given errors object on the 'errors' key
  def halt_#{underscore}(errors, render_options = {})
    halt_error(#{status}, errors, render_options)
  end
)
    else
%Q(
  # halt with status #{status} #{name}, responding with the given body object 
  def halt_#{underscore}(body, render_options = {})
    halt(#{status}, body, render_options)
  end
)
    end
  end
end.compact.join)

=end
  end
end
