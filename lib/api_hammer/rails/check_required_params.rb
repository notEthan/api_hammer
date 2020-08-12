module ApiHammer::Rails
  # halts with a 422 Unprocessable Entity and an appropriate error body if required params are missing 
  #
  # simple:
  #
  #     check_required_params(:id, :name)
  #
  # - `params[:id]` must be present
  # - `params[:name]` must be present
  #
  # less simple:
  #
  #     check_required_params(:id, :person => [:name, :height], :lucky_numbers => Array)
  #
  # - `params[:id]` must be present
  # - `params[:person]` must be present and be a hash
  # - `params[:person][:name]` must be present
  # - `params[:person][:height]` must be present
  # - `params[:lucky_numbers]` must be present and be an array
  def check_required_params(*checks)
    errors = Hash.new { |h,k| h[k] = [] }
    categories = []
    check_required_params_helper(checks, params, errors, categories, [])
    halt_unprocessable_entity(errors, error_categories: categories) if errors.any?
  end

  private
  # helper 
  def check_required_params_helper(check, subparams, errors, categories, parents)
    key = parents.join('#')
    add_error = proc do |message, category|
      errors[key] << message unless errors[key].include?(message)
      categories << category unless categories.include?(category)
    end
    if subparams.nil?
      add_error.call(I18n.t(:"errors.required_params.not_provided", :default => "%{key} is required but was not provided", :key => key), 'MISSING_PARAMETERS')
    elsif check
      case check
      when Array
        check.each { |subcheck| check_required_params_helper(subcheck, subparams, errors, categories, parents) }
      when Hash
        if subparams.is_a?(Hash) || (Object.const_defined?('ActionController') && subparams.is_a?(::ActionController::Parameters))
          check.each do |key_, subcheck|
            check_required_params_helper(subcheck, subparams[key_], errors, categories, parents + [key_])
          end
        else
          add_error.call(I18n.t(:"errors.required_params.must_be_hash", :default => "%{key} must be a Hash", :key => key), 'INVALID_PARAMETERS')
        end
      when Class
        unless subparams.is_a?(check)
          add_error.call(I18n.t(:"errors.required_params.must_be_type", :default => "%{key} must be a %{type}", :key => key, :type => check.name), 'INVALID_PARAMETERS')
        end
      else
        if subparams.is_a?(Hash) || (Object.const_defined?('ActionController') && subparams.is_a?(::ActionController::Parameters))
          check_required_params_helper(nil, subparams[check], errors, categories, parents + [check])
        else
          add_error.call(I18n.t(:"errors.required_params.must_be_hash", :default => "%{key} must be a Hash", :key => key), 'INVALID_PARAMETERS')
        end
      end
    end
  end
end
