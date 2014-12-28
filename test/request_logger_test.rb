proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'
require 'logger'
require 'stringio'

describe ApiHammer::RequestLogger do
  let(:logio) { StringIO.new }
  let(:logger) { Logger.new(logio) }

  it 'logs' do
    app = ApiHammer::RequestLogger.new(proc { |env| [200, {}, []] }, logger)
    app.call(Rack::MockRequest.env_for('/')).last.close
    assert_match(/200/, logio.string)
  end

  it 'colors by status' do
    {200 => :intense_green, 400 => :intense_yellow, 500 => :intense_red, 300 => :white}.each do |status, color|
      app = ApiHammer::RequestLogger.new(proc { |env| [status, {}, []] }, logger)
      app.call(Rack::MockRequest.env_for('/')).last.close
      assert(logio.string.include?(Term::ANSIColor.send(color, status.to_s)))
    end
  end

  it 'logs id and uuid (json)' do
    body = %Q({"uuid": "theuuid", "foo_uuid": "thefoouuid", "id": "theid", "id_for_x": "theidforx", "bar.id": "thebarid", "baz-guid": "bazzz", "bigthing": "#{' ' * 4096}"})
    app = ApiHammer::RequestLogger.new(proc { |env| [200, {"Content-Type" => 'application/json; charset=UTF8'}, [body]] }, logger)
    app.call(Rack::MockRequest.env_for('/')).last.close
    assert_match(%q("body_ids":{"uuid":"theuuid","foo_uuid":"thefoouuid","id":"theid","id_for_x":"theidforx","bar.id":"thebarid","baz-guid":"bazzz"}), logio.string)
  end

  it 'logs id and uuid (json array)' do
    body = %Q([{"uuid": "theuuid", "foo_uuid": "thefoouuid"}, {"id": "theid", "id_for_x": "theidforx"}, {"bar.id": "thebarid", "baz-guid": "bazzz", "bigthing": "#{' ' * 4096}"}])
    app = ApiHammer::RequestLogger.new(proc { |env| [200, {"Content-Type" => 'application/json; charset=UTF8'}, [body]] }, logger)
    app.call(Rack::MockRequest.env_for('/')).last.close
    assert_match(%q("body_ids":[{"uuid":"theuuid","foo_uuid":"thefoouuid"},{"id":"theid","id_for_x":"theidforx"},{"bar.id":"thebarid","baz-guid":"bazzz"}]), logio.string)
  end

  it 'logs id and uuid (form encoded)' do
    body = %Q(uuid=theuuid&foo_uuid=thefoouuid&id=theid&id_for_x=theidforx&bar.id=thebarid&baz-guid=bazzz&bigthing=#{' ' * 4096})
    app = ApiHammer::RequestLogger.new(proc { |env| [200, {"Content-Type" => 'application/x-www-form-urlencoded; charset=UTF8'}, [body]] }, logger)
    app.call(Rack::MockRequest.env_for('/')).last.close
    assert_match(%q("body_ids":{"uuid":"theuuid","foo_uuid":"thefoouuid","id":"theid","id_for_x":"theidforx","bar.id":"thebarid","baz-guid":"bazzz"}), logio.string)
  end

  it 'logs not-too-big request response bodies' do
    app = ApiHammer::RequestLogger.new(proc { |env| [200, {}, ['the_response_body']] }, logger)
    app.call(Rack::MockRequest.env_for('/', :input => 'the_request_body')).last.close
    assert_match(/"request":\{.*"body":"the_request_body/, logio.string)
    assert_match(/"response":\{.*"body":"the_response_body/, logio.string)
  end

  it 'logs request and response body on error (even if big)' do
    app = ApiHammer::RequestLogger.new(proc { |env| [400, {}, ["the_response_body #{' ' * 4096}"]] }, logger)
    app.call(Rack::MockRequest.env_for('/', :input => "the_request_body #{' ' * 4096}")).last.close
    assert_match(/"request":\{.*"body":"the_request_body/, logio.string)
    assert_match(/"response":\{.*"body":"the_response_body/, logio.string)
  end
end
