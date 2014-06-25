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
end
