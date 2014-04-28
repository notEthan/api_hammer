require 'api_hammer/version'

module ApiHammer
  autoload :Rails, 'api_hammer/rails'
  autoload :RequestLogger, 'api_hammer/request_logger.rb'
  autoload :ShowTextExceptions, 'api_hammer/show_text_exceptions.rb'
  autoload :TrailingNewline, 'api_hammer/trailing_newline.rb'
  autoload :Weblink, 'api_hammer/weblink.rb'
end
