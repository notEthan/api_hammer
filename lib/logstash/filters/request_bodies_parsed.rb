require "logstash/filters/base"
require "logstash/namespace"
require 'rack'
require 'cgi'
require 'json'
require 'api_hammer/parsed_body'

class LogStash::Filters::RequestBodiesParsed < LogStash::Filters::Base
  config_name "request_bodies_parsed"
  milestone 1

  public
  def register
  end

  public
  def filter(event)
    %w(request response).each do |re|
      if event[re].is_a?(Hash) && event[re]['body'].is_a?(String)
        _, content_type = event[re].detect { |(k,_)| k =~ /\Acontent.type\z/i }
        if event[re]['headers'].is_a?(Hash) && !content_type
          _, content_type = event[re]['headers'].detect { |(k,_)| k =~ /\Acontent.type\z/i }
        end
        parsed_body = ApiHammer::Body.new(event[re]['body'], content_type)
        event[re]['body_parsed'] = parsed_body.object if parsed_body.object
      end
    end
  end
end
