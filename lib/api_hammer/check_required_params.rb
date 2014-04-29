module ApiHammer::Rails
  # halts with a 422 Unprocessable Entity and an appropriate error body if required params are missing 
  #
  # simple:
  #
  #     check_required_params(:id, :name)
  #
  # - params[:id] must be present
  # - params[:name] must be present
  #
  # less simple:
  #
  #     check_required_params(:id, :person => [:name, :height], :lucky_numbers => Array)
  #
  # - params[:id] must be present
  # - params[:person] must be present and be a hash
  # - params[:person][:name] must be present
  # - params[:person][:height] must be present
  # - params[:lucky_numbers] must be present and be an array
  def check_required_params(*checks)
    errors = Hash.new { |h,k| h[k] = [] }
    check_required_params_helper(checks, params, errors, [])
    halt_unprocessable_entity(errors) if errors.any?
  end

  private
  # helper 
  def check_required_params_helper(check, subparams, errors, parents)
    key = parents.join('#')
    add_error = proc { |message| errors[key] << message unless errors[key].include?(message) }
    if subparams.nil?
      add_error.call("is required but was not provided")
    elsif check
      case check
      when Array
        check.each { |subcheck| check_required_params_helper(subcheck, subparams, errors, parents) }
      when Hash
        if subparams.is_a?(Hash)
          check.each do |key, subcheck|
            check_required_params_helper(subcheck, subparams[key], errors, parents + [key])
          end
        else
          add_error.call("must be a Hash")
        end
      when Class
        unless subparams.is_a?(check)
          add_error.call("must be a #{check.name}")
        end
      else
        if subparams.is_a?(Hash)
          check_required_params_helper(nil, subparams[check], errors, parents + [check])
        else
          add_error.call("must be a Hash")
        end
      end
    end
  end
end
