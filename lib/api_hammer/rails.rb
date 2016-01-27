require 'api_hammer/rails/halt'
require 'api_hammer/rails/check_required_params'
require 'api_hammer/rails/unmunged_request_params'

module ApiHammer
  module Rails
    def self.included(klass)
      (@on_included || []).each do |included_proc|
        included_proc.call(klass)
      end
    end
  end
end
