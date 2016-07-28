proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

require 'api_hammer/ycomb'
describe 'ycomb' do
  it 'does the needful' do
    length = ycomb do |len|
      proc{|list| list == [] ? 0 : 1 + len.call(list[1..-1]) }
    end
    assert_equal(0, length.call([]))
    assert_equal(3, length.call([:a, :b, :c]))
  end
end
