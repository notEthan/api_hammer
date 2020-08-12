proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

class FakeController
  def self.rescue_from(*args)
  end
  
  include(ApiHammer::Rails)
  attr_accessor :params
end

# strong parameters doesn't require its dependencies so good
require 'rack/test'
require 'active_support/core_ext/module'
require 'action_controller/metal/strong_parameters'

[Hash, ActionController::Parameters].each do |params_class|
  describe "ApiHammer::Rails#check_required_params with #{params_class}" do
    define_method(:controller_with_params) do |params|
      FakeController.new.tap { |c| c.params = params_class.new.merge(params) }
    end

    describe 'a moderately complex set of checks' do
      let(:checks) { [:id, :person => [:name, :height], :lucky_numbers => Array] }

      it 'passes with a moderately complex example' do
        c = controller_with_params(:id => '99', :person => {:name => 'hammer', :height => '3'}, :lucky_numbers => ['2'])
        c.check_required_params(checks)
      end

      it 'is missing id' do
        c = controller_with_params(:person => {:name => 'hammer', :height => '3'}, :lucky_numbers => ['2'])
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
        assert_equal({'error_message' => 'id is required but was not provided', 'errors' => {'id' => ['id is required but was not provided']}, 'error_categories' => ['MISSING_PARAMETERS']}, err.body)
      end

      it 'is missing person' do
        c = controller_with_params(:id => '99', :lucky_numbers => ['2'])
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
        assert_equal({'error_message' => 'person is required but was not provided', 'errors' => {'person' => ['person is required but was not provided']}, 'error_categories' => ['MISSING_PARAMETERS']}, err.body)
      end

      it 'is has the wrong type for person' do
        c = controller_with_params(:id => '99', :person => ['hammer', '3'], :lucky_numbers => ['2'])
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
        assert_equal({'error_message' => 'person must be a Hash', 'errors' => {'person' => ['person must be a Hash']}, 'error_categories' => ['INVALID_PARAMETERS']}, err.body)
      end

      it 'is has the wrong type for person with hash check' do
        c = controller_with_params(:person => [])
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(:person => {:id => Fixnum}) }
        assert_equal({'error_message' => 'person must be a Hash', 'errors' => {'person' => ['person must be a Hash']}, 'error_categories' => ['INVALID_PARAMETERS']}, err.body)
      end

      it 'is missing person#name' do
        c = controller_with_params(:id => '99', :person => {:height => '3'}, :lucky_numbers => ['2'])
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
        assert_equal({'error_message' => 'person#name is required but was not provided', 'errors' => {'person#name' => ['person#name is required but was not provided']}, 'error_categories' => ['MISSING_PARAMETERS']}, err.body)
      end

      it 'is missing lucky_numbers' do
        c = controller_with_params(:id => '99', :person => {:name => 'hammer', :height => '3'})
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
        assert_equal({'error_message' => 'lucky_numbers is required but was not provided', 'errors' => {'lucky_numbers' => ['lucky_numbers is required but was not provided']}, 'error_categories' => ['MISSING_PARAMETERS']}, err.body)
      end

      it 'has the wrong type for lucky_numbers' do
        c = controller_with_params(:id => '99', :person => {:name => 'hammer', :height => '3'}, :lucky_numbers => '2')
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
        assert_equal({'error_message' => 'lucky_numbers must be a Array', 'errors' => {'lucky_numbers' => ['lucky_numbers must be a Array']}, 'error_categories' => ['INVALID_PARAMETERS']}, err.body)
      end

      it 'has multiple problems' do
        c = controller_with_params({})
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
        assert_equal({'error_message' => 'id is required but was not provided. person is required but was not provided. lucky_numbers is required but was not provided.', 'errors' => {'id' => ['id is required but was not provided'], 'person' => ['person is required but was not provided'], 'lucky_numbers' => ['lucky_numbers is required but was not provided']}, 'error_categories' => ['MISSING_PARAMETERS']}, err.body)
      end
    end
  end
end
