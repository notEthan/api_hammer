require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Sidekiq < LogStash::Filters::Base
  config_name "sidekiq"
  milestone 1

  config :consume, :validate => :boolean, :default => true
  config :source, :validate => :string, :default => 'message'

  public
  def register
  end

  public
  def filter(event)
    sidekiq_logged = /\A(?<time>[\d\-]+T[\d:]+Z) (?<pid>\d+) TID-(?<tid>\w+)(?<context>.*?) (?<severity>(?i:DEBUG|INFO|WARN|ERROR|FATAL|UNKNOWN|ANY)): /
    if sidekiq_match = event[@source].match(sidekiq_logged)
      event['sidekiq'] ||= {}
      event['sidekiq'].update(sidekiq_match.names.map { |name| {name => sidekiq_match[name]} }.inject({}, &:update))

      # extract more info from context 
      job_context = /\A\s*(?<job_name>.+) JID-(?<jid>\w+)\z/
      if context_match = sidekiq_match['context'].match(job_context)
        event['sidekiq']['context'] = context_match.names.map { |name| {name => context_match[name]} }.inject({}, &:update)
      end

      event[@source] = sidekiq_match.post_match if @consume
    end
  end
end
