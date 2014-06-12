proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

require 'active_support/cache'
require 'active_record'
require 'api_hammer/active_record_find_with_caching'

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
  include ApiHammer::ActiveRecord::FindWithCaching
  cache_finder(:find_by_title)
  cache_finder(:find)
  cache_finder(:find_by_title_and_performer)
end

module Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end
end

describe ApiHammer::ActiveRecord::FindWithCaching do
  after do
    Album.destroy_all
    Rails.cache.clear
  end

  it('caches #find by primary key') do
    id = Album.create!(:title => 'x').id
    key = "albums/find/#{id}"
    assert !Rails.cache.read("albums/find_by_title/x")
    assert !Rails.cache.read(key)
    assert Album.find(id)
    assert Rails.cache.read(key)
  end

  it('caches with one attribute') do
    Album.create!(:title => 'x')
    key = "albums/find_by_title/x"
    assert !Rails.cache.read(key)
    assert Album.find_by_title('x')
    assert Rails.cache.read(key)
  end

  it('does not cache with one attribute') do
    Album.create!(:performer => 'x')
    key = "albums/find_by_performer/x"
    assert !Rails.cache.read(key)
    assert Album.find_by_performer('x')
    assert !Rails.cache.read(key)
  end

  it('caches with two attributes') do
    Album.create!(:title => 'x', :performer => 'y')
    key = "albums/find_by_title_and_performer/x/y"
    assert !Rails.cache.read(key)
    assert Album.find_by_title_and_performer('x', 'y')
    assert Rails.cache.read(key)
  end

  it('flushes cache on save') do
    album = Album.create!(:title => 'x', :performer => 'y')
    key1 = "albums/find_by_title_and_performer/x/y"
    assert !Rails.cache.read(key1), Rails.cache.instance_eval { @data }.inspect
    assert Album.find_by_title_and_performer('x', 'y'), Album.all.inspect
    assert Rails.cache.read(key1), Rails.cache.instance_eval { @data }.inspect
    key2 = "albums/find_by_title/x"
    assert !Rails.cache.read(key2), Rails.cache.instance_eval { @data }.inspect
    assert Album.find_by_title('x'), Album.all.inspect
    assert Rails.cache.read(key2), Rails.cache.instance_eval { @data }.inspect
    album.update_attributes!(:performer => 'z')
    assert !Rails.cache.read(key1), Rails.cache.instance_eval { @data }.inspect
    assert !Rails.cache.read(key2), Rails.cache.instance_eval { @data }.inspect    
  end

  it('will not try to cache initializer methods') do
    assert_raises(ArgumentError) { Album.cache_finder :find_or_initialize_by_title }
  end

  it('will not try to cache finders for all') do
    assert_raises(ArgumentError) { Album.cache_finder :find_all_by_title }
  end

  it('will not try to cache some random method not recognizeble as a finder') do
    assert_raises(ArgumentError) { Album.cache_finder :hello }
  end
end
