class PublicForwarder < BasicObject
  def initialize(object)
    @object=object
  end

  # forwards public methods to the object. attempting to invoke private or 
  # protected methods raises, as it would if the object was a normal receiver.
  def method_missing(method, *args, &block)
    if @object.protected_methods.any?{|pm| pm.to_s == method.to_s }
      ::Kernel.raise ::NoMethodError, "protected method `#{method}' called for #{@object.inspect}"
    elsif @object.private_methods.any?{|pm| pm.to_s == method.to_s }
      ::Kernel.raise ::NoMethodError, "private method `#{method}' called for #{@object.inspect}"
    else
      @object.__send__(method, *args, &block)
    end
  end
end

class Object
  # like instance_exec, but only gives access to public methods. no private or protected methods, no 
  # instance variables. 
  def public_instance_exec(*args, &block)
    PublicForwarder.new(self).instance_exec(*args, &block)
  end

  # like instance_eval, but only gives access to public methods. no private or protected methods, no 
  # instance variables. 
  def public_instance_eval(&block)
    PublicForwarder.new(self).instance_eval(&block)
  end
end
