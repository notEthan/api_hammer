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
