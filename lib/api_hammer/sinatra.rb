require 'api_hammer/sinatra/halt'

module ApiHammer
  module Sinatra
    def self.included(klass)
      (@on_included || []).each do |included_proc|
        included_proc.call(klass)
      end
    end

    include ApiHammer::Sinatra::Halt
  end
end
