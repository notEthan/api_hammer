proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

describe ApiHammer::ShowTextExceptions do
  it 'lets normal responses through untouched' do
    orig_response = [200, {}, []]
    app = ApiHammer::ShowTextExceptions.new(proc { |env| orig_response }, {})
    app_response = app.call(Rack::MockRequest.env_for('/'))
    assert_equal(orig_response, app_response)
  end
  it '500s' do
    app = ApiHammer::ShowTextExceptions.new(proc { |env| raise }, :full_error => true)
    assert_equal(500, app.call(Rack::MockRequest.env_for('/')).first)
  end
  it 'includes the full error' do
    app = ApiHammer::ShowTextExceptions.new(proc { |env| raise 'foo' }, :full_error => true)
    assert_match(/RuntimeError: foo/, app.call(Rack::MockRequest.env_for('/')).last.to_enum.to_a.join)
  end
  it 'does not include the full error' do
    app = ApiHammer::ShowTextExceptions.new(proc { |env| raise }, :full_error => false)
    assert_equal("Internal Server Error\n", app.call(Rack::MockRequest.env_for('/')).last.to_enum.to_a.join)
  end
  it 'logs' do
    logio=StringIO.new
    app = ApiHammer::ShowTextExceptions.new(proc { |env| raise 'foo' }, :logger => Logger.new(logio))
    app.call(Rack::MockRequest.env_for('/'))
    assert_match(/RuntimeError: foo/, logio.string)
  end
end
