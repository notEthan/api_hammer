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
end

module Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end
end

describe ApiHammer::ActiveRecord::FindWithCaching do
  it('caches') do
    Album.create!(:title => 'x')
    key = "albums/find_by_title/x"
    assert !Rails.cache.read("albums/find_by_title/x")
    assert Album.find_by_title('x')
  end
end
