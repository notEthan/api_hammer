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
