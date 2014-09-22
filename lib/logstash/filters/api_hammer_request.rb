require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::ApiHammerRequest < LogStash::Filters::Base
  config_name "api_hammer_request"
  milestone 1

  config :source, :validate => :string, :default => 'message'

  public
  def register
  end

  public
  def filter(event)
    # discard the request status line for humans - always followed by json which we'll parse 
    col = /[\e\[\dm]*/.source
    human_request = [/\A/, /[<>]/, /\s/, /\d+/, / : /, /\w+/, / /, /[^\e]+/, / @ /, /[^\e]+/, /\z/].map(&:source).join(col)
    event.cancel if event[@source] =~ /#{human_request}/

    begin
      parsed_message = JSON.parse(event['message'])
    rescue JSON::ParserError
      nil
    end

    if parsed_message
      if parsed_message.is_a?(Hash)
        event.to_hash.update(parsed_message)
      else
        event['parsed_message'] = parsed_message
      end
    end
  end
end
