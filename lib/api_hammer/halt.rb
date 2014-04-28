# the contents of this file are to let you halt a controller in its processing without having to have a 
# return in the actual action. this lets helper methods which do things like parameter validation halt.
#
# it is desgined to function similarly to Sinatra's handling of throw(:halt), but is based around exceptions 
# because rails doesn't catch anything, just rescues. 

module ApiHammer
  # an exception raised to stop processing an action and render the body given as the 'body' argument 
  # (which is expected to be a JSON-able object)
  class Halt < StandardError
    def initialize(message, body, render_options={})
      super(message)
      @body = body
      @render_options = render_options
    end

    attr_reader :body, :render_options
  end
end

module ApiHammer::Rails
  unless const_defined?(:HALT_INCLUDED)
    HALT_INCLUDED = proc do |controller_class|
      controller_class.send(:rescue_from, ApiHammer::Halt, :with => :handle_halt)
    end
    (@on_included ||= Set.new) << HALT_INCLUDED
  end

  # handle a raised ApiHammer::Halt or subclass and render it
  def handle_halt(halt)
    render_options = halt.render_options ? halt.render_options.dup : {}
    # rocket pants does not have a render method, just render_json 
    if respond_to?(:render_json, true)
      render_json(halt.body || {}, render_options)
    else
      render_options[:json] = halt.body || {}
      render(render_options)
    end
  end

  def halt(status, body, render_options = {})
    raise(ApiHammer::Halt.new(body.inspect, body, render_options.merge(:status => status)))
  end

  # 
  def halt_error(status, errors, render_options = {})
    halt(status, {'errors' => errors}, render_options)
  end

  def halt_bad_request(errors, render_options = {})
    halt_error(400, errors, render_options)
  end

  def halt_unprocessable_entity(errors, render_options = {})
    halt_error(422, errors, render_options)
  end
end
