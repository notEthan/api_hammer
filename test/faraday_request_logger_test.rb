# encoding: utf-8

proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'
require 'logger'
require 'stringio'
require 'api_hammer/faraday/request_logger'

describe ApiHammer::RequestLogger do
  let(:logio) { StringIO.new }
  let(:logger) { Logger.new(logio) }

  it 'logs' do
    conn = Faraday.new do |f|
      f.use ApiHammer::Faraday::RequestLogger, logger
      f.use Faraday::Adapter::Rack, proc { |env| [200, {}, []] }
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
        f.use Faraday::Adapter::Rack, proc { |env| [status, {}, []] }
      end
      conn.get '/'
      assert(logio.string.include?(Term::ANSIColor.send(color, status.to_s)))
    end
  end

  it 'registers by name' do
    conn = Faraday.new do |f|
      f.request :api_hammer_request_logger, logger
      f.use Faraday::Adapter::Rack, proc { |env| [200, {}, []] }
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
        f.use Faraday::Adapter::Rack, app
      end
      conn.get '/'
      assert_match(/Jalapeños/, logio.string)
    end

    it 'deals with encoding not specified by the content type' do
      app = proc do |env|
        [200, {}, ["Jalapeños".force_encoding("ASCII-8BIT")]]
      end
      conn = Faraday.new do |f|
        f.request :api_hammer_request_logger, logger
        f.use Faraday::Adapter::Rack, app
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
        f.use Faraday::Adapter::Rack, app
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
        f.use Faraday::Adapter::Rack, app
      end
      conn.get '/'
      assert_match('[120,120,195]', logio.string)
    end
  end
end
