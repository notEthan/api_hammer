# v0.13.4
- some rails 5 support
  - check_required_params to support ActionController::Parameters #44
  - handle not loading deprecated log_tailer when not found #33
  - use ruby String#bytesize instead of Rack::Util #34
- fix same bug as v0.13.3 with logging non-ascii bodies on faraday logger #35

# v0.13.3
- fix bug when logging non-ascii bodies with filtration enabled #31

# v0.13.2
- fix with_indifferent_access usage when we don't depend on activesupport #29

# v0.13.1
- ApiHammer::Sinatra class method use_with_lint
- set up Rack::Accept middleware in sinatra as api hammer methods rely on that

# v0.13.0
- ApiHammer::Sinatra, with some useful sinatra methods
  - #halt, #halt_error, #halt_unprocessable_entity and friends
  - a more api-appropriate 404 for unknown routes
  - parsing request bodies in accordance with content-type, with appropriate errors
  - formatting response bodies, minding accept headers, with appropriate errors

# v0.12.0
- hc --input option
- rails 4 support for unmunged_request_params

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
