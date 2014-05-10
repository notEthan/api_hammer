proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

require 'api_hammer/public_instance_exec'

class Foo
  def public_method(arg = :public)
    arg
  end
  protected
  def protected_method(arg = :protected)
    arg
  end
  private
  def private_method(arg = :private)
    arg
  end
end

describe '#public_instance_exec' do
  it 'does things' do
    foo = Foo.new
    assert_equal(:public_exec, foo.public_instance_exec(:public_exec) { |arg| public_method(arg) })
    regularex = (foo.protected_method rescue $!)
    ex = assert_raises(regularex.class) { foo.public_instance_exec(:protected_exec) { |arg| protected_method(arg) } }
    assert_equal(regularex.message, ex.message)
    regularex = (foo.private_method rescue $!)
    ex = assert_raises(regularex.class) { foo.public_instance_exec(:private_exec) { |arg| private_method(arg) } }
    assert_equal(regularex.message, ex.message)
  end
end
describe '#public_instance_eval' do
  it 'does things' do
    foo = Foo.new
    assert_equal(:public, foo.public_instance_eval { public_method })
    regularex = (foo.protected_method rescue $!)
    ex = assert_raises(regularex.class) { foo.public_instance_eval { protected_method } }
    assert_equal(regularex.message, ex.message)
    regularex = (foo.private_method rescue $!)
    ex = assert_raises(regularex.class) { foo.public_instance_eval { private_method } }
    assert_equal(regularex.message, ex.message)
  end
end
