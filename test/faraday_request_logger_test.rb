# encoding: utf-8

proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'
require 'logger'
require 'stringio'

describe ApiHammer::RequestLogger do
  let(:logio) { StringIO.new }
  let(:logger) { Logger.new(logio) }

  it 'logs' do
    conn = Faraday.new do |f|
      f.use ApiHammer::Faraday::RequestLogger, logger
      f.adapter Faraday::Adapter::Rack, proc { |env| [200, {}, []] }
    end
    conn.get '/'
    assert_match(/200/, logio.string)
    lines = logio.string.split("\n")
    assert_equal(2, lines.size)
    assert lines.last =~ /INFO -- : /
    json_bit = $'
    JSON.parse json_bit # should not raise 
  end

  {200 => :intense_green, 400 => :intense_yellow, 500 => :intense_red, 300 => :white}.each do |status, color|
    it "colors by #{status} status" do
      conn = Faraday.new do |f|
        f.use ApiHammer::Faraday::RequestLogger, logger
        f.adapter Faraday::Adapter::Rack, proc { |env| [status, {}, []] }
      end
      conn.get '/'
      assert(logio.string.include?(Term::ANSIColor.send(color, status.to_s)))
    end
  end

  it 'registers by name' do
    conn = Faraday.new do |f|
      f.request :api_hammer_request_logger, logger
      f.adapter Faraday::Adapter::Rack, proc { |env| [200, {}, []] }
    end
    conn.get '/'
    assert_match(/200/, logio.string)
  end

  describe 'response body encoding' do
    it 'deals with encoding specified properly by the content type' do
      app = proc do |env|
        [200, {'Content-Type' => 'text/plain; charset=utf-8'}, ["Jalapeños".force_encoding("ASCII-8BIT")]]
      end
      conn = Faraday.new do |f|
        f.request :api_hammer_request_logger, logger
        f.adapter Faraday::Adapter::Rack, app
      end
      conn.get '/'
      assert_match(/Jalapeños/, logio.string)
    end

    it 'deals content type specifying no encoding' do
      app = proc do |env|
        [200, {'Content-Type' => 'text/plain; x=y'}, ["Jalapeños".force_encoding("ASCII-8BIT")]]
      end
      conn = Faraday.new do |f|
        f.request :api_hammer_request_logger, logger
        f.adapter Faraday::Adapter::Rack, app
      end
      conn.get '/'
      assert_match(/Jalapeños/, logio.string)
    end

    it 'deals with no content type' do
      app = proc do |env|
        [200, {}, ["Jalapeños".force_encoding("ASCII-8BIT")]]
      end
      conn = Faraday.new do |f|
        f.request :api_hammer_request_logger, logger
        f.adapter Faraday::Adapter::Rack, app
      end
      conn.get '/'
      assert_match(/Jalapeños/, logio.string)
    end

    it 'falls back to array of codepoints when encoding is improperly specified by the content type' do
      app = proc do |env|
        [200, {'Content-Type' => 'text/plain; charset=utf-8'}, ["xx" + [195].pack("C*")]]
      end
      conn = Faraday.new do |f|
        f.request :api_hammer_request_logger, logger
        f.adapter Faraday::Adapter::Rack, app
      end
      conn.get '/'
      assert_match('[120,120,195]', logio.string)
    end

    it 'falls back to array of codepoints when encoding is not specified and not valid utf8' do
      app = proc do |env|
        [200, {}, ["xx" + [195].pack("C*")]]
      end
      conn = Faraday.new do |f|
        f.request :api_hammer_request_logger, logger
        f.adapter Faraday::Adapter::Rack, app
      end
      conn.get '/'
      assert_match('[120,120,195]', logio.string)
    end
  end
  describe 'logging body by content-type' do
    {
      'application/octet-stream' => false,
      'image/png' => false,
      'image/png; charset=what' => false,
      'text/plain' => true,
      'text/plain; charset=utf-8' => true,
    }.each do |content_type, istext|
      it "does #{istext ? '' : 'not'} log body for #{content_type}" do
        app = proc do |env|
          [200, {'Content-Type' => content_type}, ['data go here']]
        end
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.get '/'
        assert(logio.string.include?('data go here') == istext)
      end
    end
  end

  describe 'log_bodies' do
    it 'does not log bodies when log_bodies is false' do
      app = proc do |env|
        [200, {'Content-Type' => 'text/plain'}, ['data go here']]
      end
      conn = Faraday.new do |f|
        f.request :api_hammer_request_logger, logger, :log_bodies => false
        f.adapter Faraday::Adapter::Rack, app
      end
      conn.get '/'
      assert(!logio.string.include?('data go here'))
    end
  end

  describe 'filtering' do
    describe 'json response' do
      it 'filters' do
        app = proc { |env| [200, {'Content-Type' => 'application/json'}, ['{"pin": "foobar", "bar": "baz"}']] }
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger, :filter_keys => 'pin'
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.get '/'
        assert_includes(logio.string, %q("body":"{\"pin\": \"[FILTERED]\", \"bar\": \"baz\"}"))
      end
      it 'filters nested' do
        app = proc { |env| [200, {'Content-Type' => 'application/json'}, ['{"object": {"pin": "foobar"}, "bar": "baz"}']] }
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger, :filter_keys => 'pin'
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.get '/'
        assert_includes(logio.string, %q("body":"{\"object\": {\"pin\": \"[FILTERED]\"}, \"bar\": \"baz\"}"))
      end
      it 'filters in array' do
        app = proc { |env| [200, {'Content-Type' => 'application/json'}, ['[{"object": [{"pin": ["foobar"]}], "bar": "baz"}]']] }
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger, :filter_keys => 'pin'
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.get '/'
        assert_includes(logio.string, %q("body":"[{\"object\": [{\"pin\": \"[FILTERED]\"}], \"bar\": \"baz\"}]"))
      end
    end

    describe 'json request' do
      it 'filters a json request' do
        app = proc { |env| [200, {}, []] }
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger, :filter_keys => 'pin'
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.post '/', '[{"object": [{"pin": ["foobar"]}], "bar": "baz"}]', {'Content-Type' => 'application/json'}
        assert_includes(logio.string, %q("body":"[{\"object\": [{\"pin\": \"[FILTERED]\"}], \"bar\": \"baz\"}]"))
      end
    end

    describe 'form encoded response' do
      it 'filters' do
        app = proc { |env| [200, {'Content-Type' => 'application/x-www-form-urlencoded'}, ['pin=foobar&bar=baz']] }
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger, :filter_keys => 'pin'
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.get '/'
        assert_includes(logio.string, %q("body":"pin=[FILTERED]&bar=baz"))
      end
      it 'filters nested' do
        app = proc { |env| [200, {'Content-Type' => 'application/x-www-form-urlencoded'}, ['object[pin]=foobar&bar=baz']] }
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger, :filter_keys => 'pin'
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.get '/'
        assert_includes(logio.string, %q("body":"object[pin]=[FILTERED]&bar=baz"))
      end
      it 'filters in array' do
        app = proc { |env| [200, {'Content-Type' => 'application/x-www-form-urlencoded'}, ['object[][pin][]=foobar&bar=baz']] }
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger, :filter_keys => 'pin'
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.get '/'
        assert_includes(logio.string, %q("body":"object[][pin][]=[FILTERED]&bar=baz"))
      end
    end

    describe 'form encoded request' do
      it 'filters a json request' do
        app = proc { |env| [200, {}, []] }
        conn = Faraday.new do |f|
          f.request :api_hammer_request_logger, logger, :filter_keys => 'pin'
          f.adapter Faraday::Adapter::Rack, app
        end
        conn.post '/', 'object[pin]=foobar&bar=baz', {'Content-Type' => 'application/x-www-form-urlencoded'}
        assert_includes(logio.string, %q(object[pin]=[FILTERED]&bar=baz))
      end
    end
  end
end
