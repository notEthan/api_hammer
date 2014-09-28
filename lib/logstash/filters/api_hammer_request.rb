require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::ApiHammerRequest < LogStash::Filters::Base
  config_name "api_hammer_request"
  milestone 1

  config :consume, :validate => :boolean, :default => true
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
      parsed_message = JSON.parse(event[@source])
      event.remove(@source) if @consume
    rescue JSON::ParserError
      nil
    end

    if parsed_message
      if parsed_message.is_a?(Hash)
        event.to_hash.update(parsed_message)
        if parsed_message['processing'].is_a?(Hash) && parsed_message['processing']['began_at'].is_a?(Integer)
          event['@timestamp'] = Time.at(parsed_message['processing']['began_at']).utc
        end
      else
        event['parsed_message'] = parsed_message
      end
    end
  end
end
