require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::RubyLogger < LogStash::Filters::Base
  config_name "ruby_logger"
  milestone 1

  config :consume, :validate => :boolean, :default => true
  config :source, :validate => :string, :default => 'message'

  public
  def register
  end

  public
  def filter(event)
    ruby_logged = /\A(?<severity_letter>\w), +\[(?<time>[\d\-T.:]+) +#(?<pid>\d+)\] +(?<severity>(?i:DEBUG|INFO|WARN|ERROR|FATAL|UNKNOWN|ANY)) +-- +(?<progname>.*?): /
    if ruby_log_match = event[@source].match(ruby_logged)
      uninteresting_names = %w(severity_letter time)
      interesting_names = ruby_log_match.names - uninteresting_names
      event.to_hash.update(interesting_names.map { |name| {name => ruby_log_match[name]} }.inject({}, &:update))

      event['@timestamp'] = Time.parse(ruby_log_match['time']).utc

      event[@source] = ruby_log_match.post_match if @consume
    end
  end
end
