proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

describe ApiHammer::TrailingNewline do
  it 'adds a trailing newline when one is missing' do
    app = ApiHammer::TrailingNewline.new(proc { |env| [200, {}, ["foo"]] })
    assert_equal("foo\n", app.call(Rack::MockRequest.env_for('/')).last.to_enum.to_a.join)
  end

  it 'does not add a trailing newline when one is present' do
    app = ApiHammer::TrailingNewline.new(proc { |env| [200, {}, ["foo\n"]] })
    assert_equal("foo\n", app.call(Rack::MockRequest.env_for('/')).last.to_enum.to_a.join)
  end

  it 'does not add a trailing newline when the response is blank' do
    app = ApiHammer::TrailingNewline.new(proc { |env| [200, {}, []] })
    assert_equal([], app.call(Rack::MockRequest.env_for('/')).last.to_enum.to_a)
  end

  it 'updates Content-Length if present' do
    app = ApiHammer::TrailingNewline.new(proc { |env| [200, {'Content-Length' => '3'}, ['foo']] })
    assert_equal('4', app.call(Rack::MockRequest.env_for('/'))[1]['Content-Length'])
  end
end
