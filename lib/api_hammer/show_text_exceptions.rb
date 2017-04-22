module ApiHammer
  # Rack middleware to rescue any exceptions and return an appropriate message for the current 
  # environment, with a nice concise bit of text for errors. 
  #
  # ideally this should be placed as close to the application itself as possible (last middleware 
  # used) so that the exception will not bubble past other middleware, skipping it. 
  # 
  # like Sinatra::ShowExceptions or Rack::ShowExceptions, but not a huge blob of html. (note:
  # those middlewares have a #prefers_plain_text? method which makes them behave like this, but 
  # it's simpler and more reliable to roll our own than monkey-patch those) 
  class ShowTextExceptions
    # this module blatantly stolen from
    # https://github.com/rspec/rspec-support/blob/v3.5.0/lib/rspec/support.rb#L121-L130
    # under MIT license https://github.com/rspec/rspec-support/blob/v3.5.0/LICENSE.md
    module AllExceptionsExceptOnesWeMustNotRescue
      # These exceptions are dangerous to rescue as rescuing them
      # would interfere with things we should not interfere with.
      AVOID_RESCUING = [NoMemoryError, SignalException, Interrupt, SystemExit]

      def self.===(exception)
        AVOID_RESCUING.none? { |ar| ar === exception }
      end
    end

    def initialize(app, options)
      @app=app
      @options = options
    end
    def call(env)
      begin
        @app.call(env)
      rescue AllExceptionsExceptOnesWeMustNotRescue => e
        full_error_message = (["#{e.class}: #{e.message}"] + e.backtrace.map{|l| "  #{l}" }).join("\n")
        if @options[:logger]
          @options[:logger].error(full_error_message)
        end
        if @options[:full_error]
          body = full_error_message
        else
          body = "Internal Server Error\n"
        end
        [500, {'Content-Type' => 'text/plain'}, [body]]
      end
    end
  end
end
