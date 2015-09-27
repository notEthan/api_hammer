# v0.11.1
- bugfix trailingnewline

# v0.11.0
- improved handling of text and binary bodies in logging middleware and hc

# v0.10.2
- rails request logging logs exception backtrace

# v0.10.1
- Rack RequestLogger works around rails' exception app path mangling

# v0.10.0
- JsonScriptEscapeHelper

# v0.9.2
- bugfix form encoded filtering

# v0.9.1
- recognize `app.config.api_hammer_request_logging_options` for request logger options

# v0.9.0
- rack request logger logs ids in arrays of hashes when logging ids
- filtered logging of sensitive keys in bodies of requests (json and form encoded)
- logstash filter for oauth headers and oauthenticator log entries

# v0.8.1
- request log format tweaks

# v0.8.0
- log request and response bodies - not just IDs from them - if they aren't too big

# v0.7.1
- logstash filters for sidekiq, activesupport tags, and of course ApiHammer's request logging 
- use i18n for errors and add error_message to response
- hc assumes http if no protocol specified

# v0.6.3
- add request role to the request logging

# v0.6.2
- ApiHammer::RequestLogger response body fix

# v0.6.1
- broken release, yanked

# v0.6.0
- ApiHammer::RailsOrSidekiqLogger

# v0.5.0
- rack request logger logs all request and response headers
- fix id / uuid / guid logging in rack request logger
- faraday request logger does not log binary bodies 

# 0.4.3
- bugfix

# 0.4.2
- bugfix encoding in faraday request logger

# 0.4.1
- bugfix

# 0.4.0
- ApiHammer::Faraday::RequestLogger

# 0.3.3
- be a little lazier about initializing ActiveRecord::Base.finder_cache - only on first actual usage 

# 0.3.2
- ActiveRecord::Base.cache_find_by support finding on associations, fix bind detection with symbols 

# 0.3.1
- bugfix ActiveRecord::Base.cache_find_by

# 0.3.0
- ActiveRecord::Base.cache_find_by

# 0.2.2
- RequestLogger, in addition to logging response bodies on error, logs id/uuid fields from request body and 
  response body if there's no error
- support a logger instead of a device in FaradayOutputter

# 0.2.1
- small RequestLogger tweaks

# 0.2.0
- Rails#unmunged_request_params
- hc --pretty
- hc default User-Agent set
- hc doc improved, middlewares moved lib
- RequestLogger improved
- ApiHammer::RailsRequestLogging railtie
- README improved marginally 

# 0.1.0
- Object#public_instance_exec
- Obect#public_instance_eval
- hc

# 0.0.3
- rake cucumber:pretty_json
- Rails#find_or_halt

# 0.0.2

- Weblink#to_s

# 0.0.1

- rake gem:available_updates
- Rails#halt
- Rails#check_required_params
- Weblink
- RequestLogger
- ShowTextExceptions
- TrailingNewline
