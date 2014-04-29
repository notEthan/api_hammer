proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

class FakeController
  def self.rescue_from(*args)
  end
  
  include(ApiHammer::Rails)

  attr_reader :rendered
  def render(opts)
    @rendered = opts
  end
end

describe 'ApiHammer::Rails#halt' do
  it 'raises ApiHammer::Halt' do
    haltex = assert_raises(ApiHammer::Halt) { FakeController.new.halt(200, {}) }
    assert_equal({}, haltex.body)
    assert_equal(200, haltex.render_options[:status])
  end
  describe 'status-specific halts' do
    it 'halts ok' do
      haltex = assert_raises(ApiHammer::Halt) { FakeController.new.halt_ok({}) }
      assert_equal({}, haltex.body)
      assert_equal(200, haltex.render_options[:status])
    end
    it 'halts unprocessable entity' do
      haltex = assert_raises(ApiHammer::Halt) { FakeController.new.halt_unprocessable_entity({}) }
      assert_equal({'errors' => {}}, haltex.body)
      assert_equal(422, haltex.render_options[:status])
    end
  end
end

describe 'ApiHammer::Rails#handle_halt' do
  it 'renders the things from the error' do
    controller = FakeController.new
    haltex = (FakeController.new.halt_unprocessable_entity({}) rescue $!)
    controller.handle_halt(haltex)
    assert_equal(422, controller.rendered[:status])
    assert_equal({'errors' => {}}, controller.rendered[:json])
  end
end
