module ApiHammer::Rails
  MUTEX_FOR_THREAD = Mutex.new
  # request parameters (not query parameters) without the nil/empty array munging that rails does
  def unmunged_request_params
    # Use Mutex#synchronize to ensure that any other params parsing occurring in other
    # threads is not affected by disabling munging
    #
    # TODO when we are on a rails which has ActionDispatch::Request::Utils.perform_deep_munge, use that instead
    # of clobbering methods
    @unmunged_params ||= MUTEX_FOR_THREAD.synchronize do
      if ActionDispatch::Request.const_defined?(:Utils) && ActionDispatch::Request::Utils.respond_to?(:deep_munge)
        # rails 4
        deep_munge_owner = (class << ActionDispatch::Request::Utils; self; end)
      else
        # rails 3
        deep_munge_owner = ActionDispatch::Request
      end

      unless deep_munge_owner.method_defined?(:real_deep_munge)
        deep_munge_owner.send(:alias_method, :real_deep_munge, :deep_munge)
      end
      deep_munge_owner.send(:define_method, :deep_munge) { |hash| hash }

      begin
        unmunged_params = nil
        newenv = request.env.merge('action_dispatch.request.request_parameters' => nil)
        ActionDispatch::ParamsParser.new(proc do |env|
          unmunged_params = env['action_dispatch.request.request_parameters']
        end).call(newenv)
        unmunged_params || ActionDispatch::Request.new(newenv).request_parameters
      ensure
        deep_munge_owner.send(:alias_method, :deep_munge, :real_deep_munge)
      end
    end
  end
end
