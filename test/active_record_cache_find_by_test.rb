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

  it('caches #find_by_id') do
    id = Album.create!(:title => 'x').id
    assert_caches("cache_find_by/albums/id/#{id}") { assert Album.find_by_id(id) }
  end

  it('caches #where.first with primary key') do
    id = Album.create!(:title => 'x').id
    assert_caches("cache_find_by/albums/id/#{id}") { assert Album.where(:id => id).first }
  end

  it('caches find_by_x with one attribute') do
    Album.create!(:title => 'x')
    assert_caches("cache_find_by/albums/title/x") { assert Album.find_by_title('x') }
  end

  it('caches where.first with one attribute') do
    Album.create!(:title => 'x')
    assert_caches("cache_find_by/albums/title/x") { assert Album.where(:title => 'x').first }
  end

  it('does not cache where.last with one attribute') do
    Album.create!(:title => 'x')
    assert_not_caches("cache_find_by/albums/title/x") { assert Album.where(:title => 'x').last }
  end

  it('does not cache find_by_x with one attribute') do
    Album.create!(:performer => 'x')
    assert_not_caches("cache_find_by/albums/performer/x") { assert Album.find_by_performer('x') }
  end

  it('does not cache where.first with one attribute') do
    Album.create!(:performer => 'x')
    assert_not_caches("cache_find_by/albums/performer/x") { assert Album.where(:performer => 'x').first }
  end

  it('caches find_by_x with two attributes') do
    Album.create!(:title => 'x', :performer => 'y')
    assert_caches("cache_find_by/albums/performer/y/title/x") { assert Album.find_by_title_and_performer('x', 'y') }
  end

  it('caches where.first with two attributes') do
    Album.create!(:title => 'x', :performer => 'y')
    assert_caches("cache_find_by/albums/performer/y/title/x") { assert Album.where(:title => 'x', :performer => 'y').first }
  end

  it('flushes cache on save') do
    album = Album.create!(:title => 'x', :performer => 'y')
    assert_caches(key1 = "cache_find_by/albums/performer/y/title/x") { assert Album.find_by_title_and_performer('x', 'y') }
    assert_caches(key2 = "cache_find_by/albums/title/x") { assert Album.find_by_title('x') }
    album.update_attributes!(:performer => 'z')
    assert !Rails.cache.read(key1), Rails.cache.instance_eval { @data }.inspect
    assert !Rails.cache.read(key2), Rails.cache.instance_eval { @data }.inspect
  end
end
