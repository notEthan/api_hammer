require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::ActiveSupportTags < LogStash::Filters::Base
  config_name "active_support_tags"
  milestone 1

  config :consume, :validate => :boolean, :default => true
  config :source, :validate => :string, :default => 'message'

  public
  def register
  end

  public
  def filter(event)
    as_tags = []
    message = event[@source]
    while message =~ /\A\[([^\]]+?)\]\s+/
      as_tags << $1
      message = $'
    end
    event['as_tags'] = as_tags if as_tags.any?

    event[@source] = message if @consume
  end
end
