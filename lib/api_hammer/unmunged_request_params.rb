module ApiHammer::Rails
  # request parameters (not query parameters) without the nil/empty array munging that rails does 
  def unmunged_request_params
    # Thread.exclusive is not optimal but we need to ensure that any other params parsing occurring in other 
    # threads is not affected by disabling munging
    #
    # TODO when we are on a rails which has ActionDispatch::Request::Utils.perform_deep_munge, use that instead
    # of clobbering methods
    @unmunged_params ||= Thread.exclusive do
      unless ActionDispatch::Request.method_defined?(:real_deep_munge)
        ActionDispatch::Request.send(:alias_method, :real_deep_munge, :deep_munge)
      end
      ActionDispatch::Request.send(:define_method, :deep_munge) { |hash| hash }
      begin
        unmunged_params = nil
        newenv = request.env.merge('action_dispatch.request.request_parameters' => nil)
        ActionDispatch::ParamsParser.new(proc do |env|
          unmunged_params = env['action_dispatch.request.request_parameters']
        end).call(newenv)
        unmunged_params || ActionDispatch::Request.new(newenv).request_parameters
      ensure
        ActionDispatch::Request.send(:alias_method, :deep_munge, :real_deep_munge)
      end
    end
  end
end
