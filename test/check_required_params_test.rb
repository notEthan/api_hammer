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
      err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
      assert_equal({'error_message' => 'id is required but was not provided', 'errors' => {'id' => ['id is required but was not provided']}}, err.body)
    end

    it 'is missing person' do
      c = controller_with_params(:id => '99', :lucky_numbers => ['2'])
      err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
      assert_equal({'error_message' => 'person is required but was not provided', 'errors' => {'person' => ['person is required but was not provided']}}, err.body)
    end

    it 'is has the wrong type for person' do
      c = controller_with_params(:id => '99', :person => ['hammer', '3'], :lucky_numbers => ['2'])
      err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
      assert_equal({'error_message' => 'person must be a Hash', 'errors' => {'person' => ['person must be a Hash']}}, err.body)
    end

    describe 'when ActionController::Parameters is undefined' do
      it 'it handle the array properly' do
        assert_equal(nil, defined?(ActionController::Parameters))
        c = controller_with_params(:id => '99', :person => ['hammer', '3'], :lucky_numbers => ['2'])
        err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
        assert_equal({'error_message' => 'person must be a Hash', 'errors' => {'person' => ['person must be a Hash']}}, err.body)
      end
    end

    describe 'when ActionController::Parameters is defined' do
      before do
        module ActionController
          class Parameters
            def initialize(hash)
              @hash = hash
            end
            def to_h
              @hash
            end
            def [](key)
              @hash[key]
            end
          end
        end
        assert_equal('constant', defined?(ActionController::Parameters))
      end

      after do
        ActionController.send(:remove_const, :Parameters)
        Object.send(:remove_const, :ActionController)
      end

      describe 'when sending a ActionController::Parameters as params' do
        describe 'with invalid subparams' do
          it 'it act as if it was a hash' do
            invalid_params = {:id => '99', :person => ['hammer', '3'], :lucky_numbers => ['2']}
            c = controller_with_params(ActionController::Parameters.new(invalid_params))
            err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
            assert_equal({'error_message' => 'person must be a Hash', 'errors' => {'person' => ['person must be a Hash']}}, err.body)
          end
        end
        describe 'when everything is valid' do
          it 'it act as if it was a hash' do
            person = ActionController::Parameters.new(:name => 'hammer', :height => '3')
            params = ActionController::Parameters.new(:id => '99', :person => person, :lucky_numbers => ['2'])
            c = controller_with_params(params)
            c.check_required_params(checks)
          end
        end
      end

      describe 'when sending a ActionController::Parameters as subparams' do
        it 'it act as if the subparams was a hash' do
          person = ActionController::Parameters.new(:name => 'hammer', :height => '3')
          c = controller_with_params(:id => '99', :person => person, :lucky_numbers => ['2'])
          c.check_required_params(checks)
        end
      end
    end

    it 'is missing person#name' do
      c = controller_with_params(:id => '99', :person => {:height => '3'}, :lucky_numbers => ['2'])
      err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
      assert_equal({'error_message' => 'person#name is required but was not provided', 'errors' => {'person#name' => ['person#name is required but was not provided']}}, err.body)
    end

    it 'is missing lucky_numbers' do
      c = controller_with_params(:id => '99', :person => {:name => 'hammer', :height => '3'})
      err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
      assert_equal({'error_message' => 'lucky_numbers is required but was not provided', 'errors' => {'lucky_numbers' => ['lucky_numbers is required but was not provided']}}, err.body)
    end

    it 'has the wrong type for lucky_numbers' do
      c = controller_with_params(:id => '99', :person => {:name => 'hammer', :height => '3'}, :lucky_numbers => '2')
      err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
      assert_equal({'error_message' => 'lucky_numbers must be a Array', 'errors' => {'lucky_numbers' => ['lucky_numbers must be a Array']}}, err.body)
    end

    it 'has multiple problems' do
      c = controller_with_params({})
      err = assert_raises(ApiHammer::Rails::Halt) { c.check_required_params(checks) }
      assert_equal({'error_message' => 'id is required but was not provided. person is required but was not provided. lucky_numbers is required but was not provided.', 'errors' => {'id' => ['id is required but was not provided'], 'person' => ['person is required but was not provided'], 'lucky_numbers' => ['lucky_numbers is required but was not provided']}}, err.body)
    end
  end
end
