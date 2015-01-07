require 'api_hammer/version'

module ApiHammer
  autoload :Rails, 'api_hammer/rails'
  autoload :RequestLogger, 'api_hammer/request_logger'
  autoload :ShowTextExceptions, 'api_hammer/show_text_exceptions'
  autoload :TrailingNewline, 'api_hammer/trailing_newline'
  autoload :Weblink, 'api_hammer/weblink'
  autoload :RailsOrSidekiqLoggerMiddleware, 'api_hammer/rails_or_sidekiq_logger'
  autoload :RailsOrSidekiqLogger, 'api_hammer/rails_or_sidekiq_logger'
  autoload :FaradayOutputter, 'api_hammer/faraday/outputter'
  autoload :FaradayCurlVOutputter, 'api_hammer/faraday/outputter'
  autoload :ParsedBody, 'api_hammer/parsed_body'
  autoload :ContentTypeAttrs, 'api_hammer/content_type_attrs'
  module Faraday
    autoload :RequestLogger, 'api_hammer/faraday/request_logger'
  end
  module Filtration
    autoload :Json, 'api_hammer/filtration/json'
    autoload :FormEncoded, 'api_hammer/filtration/form_encoded'
  end
end

require 'faraday'
if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware(:request, :api_hammer_request_logger => proc { ApiHammer::Faraday::RequestLogger })
end
if Faraday::Request.respond_to?(:register_middleware)
  Faraday::Request.register_middleware(:api_hammer_request_logger => proc { ApiHammer::Faraday::RequestLogger })
end
