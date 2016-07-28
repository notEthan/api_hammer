require 'api_hammer/halt_methods'

module ApiHammer
  module Sinatra
    module Halt
      # halt and render the given body 
      def halt(status, body, render_options = {})
        throw :halt, format_response(status, body)
      end

      include HaltMethods
    end
  end
end
