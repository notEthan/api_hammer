require "logstash/filters/base"
require "logstash/namespace"
require 'oauthenticator'

class LogStash::Filters::OAuthenticator < LogStash::Filters::Base
  config_name "oauthenticator"
  milestone 1

  config :consume, :validate => :boolean, :default => true
  config :source, :validate => :string, :default => 'message'

  public
  def register
  end

  public
  def filter(event)
    #OAuthenticator authenticated an authentic request with Authorization: OAuth realm="", oauth_consumer_key="ios-production-lFo4Zqgs", oauth_token="aE7wU1VPPa7G2l2VLtVRalgIOM4zKJUu7BMnQZoH", oauth_signature_method="HMAC-SHA1", oauth_version="1.0", oauth_nonce="34DA75CB-7653-4AF5-A3F8-B0989AABFCDF", oauth_timestamp="1411935761", oauth_signature="H%2F0kt3aSPqdo2qgfRrbPPirR%2F4g%3D"
    match = event[@source].match(/\A(OAuthenticator authenticated an authentic request) with Authorization: /)
    if match
      authorization = match.post_match

      begin
        event['oauth'] = OAuthenticator.parse_authorization(authorization)
      rescue OAuthenticator::Error => parse_exception
        nil
      end

      event[@source] = match[1] if @consume
    end

    # parse the authorization of a request filtered by LogStash::Filters::ApiHammerRequest
    if event['request'].is_a?(Hash) && event['request']['headers'].is_a?(Hash)
      authorization = event['request']['headers'].inject(nil) { |a, (k,v)| k.is_a?(String) && k.downcase == 'authorization' ? v : a }
      if authorization.is_a?(String)
        begin
          event['request']['oauth'] = OAuthenticator.parse_authorization(authorization)
        rescue OAuthenticator::Error => parse_exception
          # if it is not oauth or badly formed oauth we don't care 
          nil
        end
      end
    end
  end
end
