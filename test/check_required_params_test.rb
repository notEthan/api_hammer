proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

class FakeController
  def self.rescue_from(*args)
  end
  
  include(ApiHammer::Rails)
  attr_accessor :params
end

describe 'ApiHammer::Rails#check_required_params' do
  def controller_with_params(params)
    FakeController.new.tap { |c| c.params = params }
  end

  describe 'a moderately complex set of checks' do
    let(:checks) { [:id, :person => [:name, :height], :lucky_numbers => Array] }
  
    it 'passes with a moderately complex example' do
      c = controller_with_params(:id => '99', :person => {:name => 'hammer', :height => '3'}, :lucky_numbers => ['2'])
      c.check_required_params(checks)
    end

    it 'is missing id' do
      c = controller_with_params(:person => {:name => 'hammer', :height => '3'}, :lucky_numbers => ['2'])
      err = assert_raises(ApiHammer::Halt) { c.check_required_params(checks) }
      assert_equal({'errors' => {'id' => ['is required but was not provided']}}, err.body)
    end

    it 'is missing person' do
      c = controller_with_params(:id => '99', :lucky_numbers => ['2'])
      err = assert_raises(ApiHammer::Halt) { c.check_required_params(checks) }
      assert_equal({'errors' => {'person' => ['is required but was not provided']}}, err.body)
    end

    it 'is has the wrong type for person' do
      c = controller_with_params(:id => '99', :person => ['hammer', '3'], :lucky_numbers => ['2'])
      err = assert_raises(ApiHammer::Halt) { c.check_required_params(checks) }
      assert_equal({'errors' => {'person' => ['must be a Hash']}}, err.body)
    end

    it 'is missing person#name' do
      c = controller_with_params(:id => '99', :person => {:height => '3'}, :lucky_numbers => ['2'])
      err = assert_raises(ApiHammer::Halt) { c.check_required_params(checks) }
      assert_equal({'errors' => {'person#name' => ['is required but was not provided']}}, err.body)
    end

    it 'is missing lucky_numbers' do
      c = controller_with_params(:id => '99', :person => {:name => 'hammer', :height => '3'})
      err = assert_raises(ApiHammer::Halt) { c.check_required_params(checks) }
      assert_equal({'errors' => {'lucky_numbers' => ['is required but was not provided']}}, err.body)
    end

    it 'has the wrong type for lucky_numbers' do
      c = controller_with_params(:id => '99', :person => {:name => 'hammer', :height => '3'}, :lucky_numbers => '2')
      err = assert_raises(ApiHammer::Halt) { c.check_required_params(checks) }
      assert_equal({'errors' => {'lucky_numbers' => ['must be a Array']}}, err.body)
    end

    it 'has multiple problems' do
      c = controller_with_params({})
      err = assert_raises(ApiHammer::Halt) { c.check_required_params(checks) }
      assert_equal({'errors' => {'id' => ['is required but was not provided'], 'person' => ['is required but was not provided'], 'lucky_numbers' => ['is required but was not provided']}}, err.body)
    end
  end
end
