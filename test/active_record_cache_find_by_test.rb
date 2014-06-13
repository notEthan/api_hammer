proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

require 'active_support/cache'
require 'active_record'
require 'api_hammer/active_record_cache_find_by'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database  => ":memory:"
)

ActiveRecord::Schema.define do
  create_table :albums do |table|
    table.column :title, :string
    table.column :performer, :string
  end
end

class Album < ActiveRecord::Base
  cache_find_by(:id)
  cache_find_by(:title)
end

module Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end
end

describe 'ActiveRecord::Base.cache_find_by' do
  def assert_caches(key)
    assert !Rails.cache.read(key)
    yield
  ensure
    assert Rails.cache.read(key)
  end

  def assert_not_caches(key)
    assert !Rails.cache.read(key)
    yield
  ensure
    assert !Rails.cache.read(key)
  end

  it('caches') do
    Album.create!(:title => 'x')
    assert_caches("cache_find_by/albums/title/x") { assert Album.find_by_title('x') }
  end
end
