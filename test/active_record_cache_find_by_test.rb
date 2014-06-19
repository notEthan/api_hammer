proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('.', File.dirname(__FILE__)))
require 'helper'

require 'active_support/cache'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database  => ":memory:"
)

module Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end
end

require 'api_hammer/active_record_cache_find_by'

ActiveRecord::Schema.define do
  create_table :albums do |table|
    table.column :title, :string
    table.column :performer, :string
    table.column :tracks, :integer
    table.column :catalog_xid, :integer
  end
  create_table :catalogs do |table|
  end
end

class Album < ActiveRecord::Base
  belongs_to :catalog, :foreign_key => :catalog_xid
  cache_find_by(:id)
  cache_find_by(:performer)
  cache_find_by(:title, :performer)
  cache_find_by(:tracks)
  cache_find_by(:catalog_xid, :title)
end

class Catalog < ActiveRecord::Base
  has_many :albums, :foreign_key => :catalog_xid
end

class VinylAlbum < Album
  self.finder_cache = ActiveSupport::Cache::MemoryStore.new
end

describe 'ActiveRecord::Base.cache_find_by' do
  def assert_caches(key, cache = Rails.cache)
    assert !cache.read(key), "cache already contains a key #{key}: #{cache.read(key)}"
    yield
  ensure
    assert cache.read(key), "key #{key} was not cached"
  end

  def assert_not_caches(key, cache = Rails.cache)
    assert !cache.read(key), "cache already contains a key #{key}: #{cache.read(key)}"
    yield
  ensure
    assert !cache.read(key), "key was incorrectly cached - #{key}: #{cache.read(key)}"
  end

  after do
    Album.all.each(&:destroy)
    Catalog.all.each(&:destroy)
  end

  it('caches #find by primary key') do
    id = Album.create!.id
    assert_caches("cache_find_by/albums/id/#{id}") { assert Album.find(id) }
  end

  it('caches #find_by_id') do
    id = Album.create!.id
    assert_caches("cache_find_by/albums/id/#{id}") { assert Album.find_by_id(id) }
  end

  it('caches #where.first with primary key') do
    id = Album.create!.id
    assert_caches("cache_find_by/albums/id/#{id}") { assert Album.where(:id => id).first }
  end

  it('caches find_by_x with one attribute') do
    Album.create!(:performer => 'x')
    assert_caches("cache_find_by/albums/performer/x") { assert Album.find_by_performer('x') }
  end

  it('caches find_by_x! with one attribute') do
    Album.create!(:performer => 'x')
    assert_caches("cache_find_by/albums/performer/x") { assert Album.find_by_performer!('x') }
  end

  it('caches where.first with one attribute') do
    Album.create!(:performer => 'x')
    assert_caches("cache_find_by/albums/performer/x") { assert Album.where(:performer => 'x').first }
  end

  it('caches where.first! with one attribute') do
    Album.create!(:performer => 'x')
    assert_caches("cache_find_by/albums/performer/x") { assert Album.where(:performer => 'x').first! }
  end

  it('caches #where.first with integer attribute') do
    id = Album.create!(:tracks => 3).id
    assert_caches("cache_find_by/albums/tracks/3") { assert Album.where(:tracks => 3).first }
  end

  it('does not cache #where.first with inequality of integer attribute') do
    id = Album.create!(:tracks => 3).id
    assert_not_caches("cache_find_by/albums/tracks/3") { assert Album.where(Album.arel_table['tracks'].gteq(3)).first }
  end

  if ActiveRecord::Relation.method_defined?(:take)
    it('caches where.take with one attribute') do
      Album.create!(:performer => 'x')
      assert_caches("cache_find_by/albums/performer/x") { assert Album.where(:performer => 'x').take }
    end
  end

  it('does not cache where.last with one attribute') do
    Album.create!(:performer => 'x')
    assert_not_caches("cache_find_by/albums/performer/x") { assert Album.where(:performer => 'x').last }
  end

  it('does not cache find with array') do
    ids = [Album.create!.id, Album.create!.id]
    assert_not_caches("cache_find_by/albums/id/#{ids.first}") { assert Album.find(ids) }
  end

  it('does not cache find_by_x with array') do
    ids = [Album.create!.id, Album.create!.id]
    assert_not_caches("cache_find_by/albums/id/#{ids.first}") { assert Album.find_by_id(ids) }
  end

  it('does not cache where.first with array') do
    ids = [Album.create!.id, Album.create!.id]
    assert_not_caches("cache_find_by/albums/id/#{ids.first}") { assert Album.where(:id => ids).first }
  end

  it('does not cache find_by_x with one attribute') do
    Album.create!(:title => 'x')
    assert_not_caches("cache_find_by/albums/title/x") { assert Album.find_by_title('x') }
  end

  it('does not cache where.first with one attribute') do
    Album.create!(:title => 'x')
    assert_not_caches("cache_find_by/albums/title/x") { assert Album.where(:title => 'x').first }
  end

  it('caches find_by_x with two attributes') do
    Album.create!(:title => 'x', :performer => 'y')
    assert_caches("cache_find_by/albums/performer/y/title/x") { assert Album.find_by_title_and_performer('x', 'y') }
  end

  it('caches where.first with two attributes') do
    Album.create!(:title => 'x', :performer => 'y')
    assert_caches("cache_find_by/albums/performer/y/title/x") { assert Album.where(:title => 'x', :performer => 'y').first }
  end

  it('caches with two attributes on an association with a where') do
    c = Catalog.create!
    Album.create!(:title => 'x', :performer => 'y', :catalog_xid => c.id)
    c = Catalog.first
    assert_caches("cache_find_by/albums/catalog_xid/#{c.id}/title/x") { assert c.albums.where(:title => 'x').first }
  end

  it('flushes cache on save') do
    album = Album.create!(:title => 'x', :performer => 'y')
    assert_caches(key1 = "cache_find_by/albums/performer/y/title/x") { assert Album.find_by_title_and_performer('x', 'y') }
    assert_caches(key2 = "cache_find_by/albums/performer/y") { assert Album.find_by_performer('y') }
    album.update_attributes!(:performer => 'z')
    assert !Rails.cache.read(key1), Rails.cache.instance_eval { @data }.inspect
    assert !Rails.cache.read(key2), Rails.cache.instance_eval { @data }.inspect
  end

  it('flushes cache on destroy') do
    album = Album.create!(:title => 'x', :performer => 'y')
    assert_caches(key1 = "cache_find_by/albums/performer/y/title/x") { assert Album.find_by_title_and_performer('x', 'y') }
    assert_caches(key2 = "cache_find_by/albums/performer/y") { assert Album.find_by_performer('y') }
    album.destroy
    assert !Rails.cache.read(key1), Rails.cache.instance_eval { @data }.inspect
    assert !Rails.cache.read(key2), Rails.cache.instance_eval { @data }.inspect
  end

  it 'inherits cache_find_bys' do
    assert VinylAlbum.send(:cache_find_bys).any? { |f| f == ['id'] }
  end

  it 'uses a different cache when specified' do
    assert Album.finder_cache != VinylAlbum.finder_cache

    id = Album.create!.id
    key = "cache_find_by/albums/id/#{id}"
    assert_caches(key) do
      assert_not_caches(key, VinylAlbum.finder_cache) do
        assert Album.find(id)
      end
    end

    id = VinylAlbum.create!.id
    key = "cache_find_by/albums/id/#{id}"
    assert_caches(key, VinylAlbum.finder_cache) do
      assert_not_caches(key) do
        assert VinylAlbum.find(id)
      end
    end
  end

  it 'does not get confused by values with slashes' do
    Album.create!(:title => 'z', :performer => 'y/title/x')
    Album.create!(:title => 'x', :performer => 'y')

    Album.where(:performer => 'y', :title => 'x').first
    assert_equal 'z', Album.where(:performer => 'y/title/x').first.title
  end

  it 'works with a symbol on the left' do
    # this makes an association with :catalog_xid as the left side of a where_value. these are usually 
    # strings. this just makes sure it doesn't error out. 
    c = Catalog.create!
    c = Catalog.first
    c.albums.where(:title => 'y').first
  end
end
