require 'api_hammer/halt'
require 'api_hammer/check_required_params'
require 'api_hammer/unmunged_request_params'

module ApiHammer::Rails
  def self.included(klass)
    (@on_included || []).each do |included_proc|
      included_proc.call(klass)
    end
  end
end
