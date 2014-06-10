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
  cache_find_by(:title, :performer)
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

  after do
    Album.destroy_all
    Rails.cache.clear
  end

  it('caches #find by primary key') do
    id = Album.create!(:title => 'x').id
    assert_caches("cache_find_by/albums/id/#{id}") { assert Album.find(id) }
  end

  it('caches with one attribute') do
    Album.create!(:title => 'x')
    assert_caches("cache_find_by/albums/title/x") { assert Album.find_by_title('x') }
  end

  it('does not cache with one attribute') do
    Album.create!(:performer => 'x')
    assert_not_caches("cache_find_by/albums/performer/x") { assert Album.find_by_performer('x') }
  end

  it('caches with two attributes') do
    Album.create!(:title => 'x', :performer => 'y')
    assert_caches("cache_find_by/albums/performer/y/title/x") { assert Album.find_by_title_and_performer('x', 'y') }
  end
end
