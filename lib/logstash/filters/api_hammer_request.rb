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
    #               begin  direction     status        method      path             time      end
    human_request = [/\A/, /[<>]/, /\s/, /\d+/, / : /, /\w+/, / /, /[^\e]+/, / @ /, /[^\e]+/, /\z/].map(&:source).join(col)
    event.cancel if event[@source] =~ /#{human_request}/

    begin
      parsed_message = JSON.parse(event[@source])
      if @consume
        # replace the source with a brief human-readable message
        bound = parsed_message['bound']
        dir = role == 'inbound' ? '<' : role == 'outbound' ? '>' : '*'
        status = parsed_message['response'] && parsed_message['response']['status']
        request_method = parsed_message['request'] && parsed_message['request']['method']
        request_uri = parsed_message['request'] && parsed_message['request']['uri']
        now_s = Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')
        event[@source] = "#{dir} #{status} : #{request_method} #{request_uri} @ #{now_s}"
      end
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
