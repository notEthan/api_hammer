require "logstash/filters/base"
require "logstash/namespace"
require 'rack'
require 'cgi'
require 'json'
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
        media_type = ::Rack::Request.new({'CONTENT_TYPE' => content_type}).media_type
        body_parsed = begin
          if media_type == 'application/json'
            JSON.parse(event[re]['body']) rescue nil
          elsif media_type == 'application/x-www-form-urlencoded'
            CGI.parse(event[re]['body']).map { |k, vs| {k => vs.last} }.inject({}, &:update)
          end
        end
        event[re]['body_parsed'] = body_parsed if body_parsed
      end
    end
  end
end
