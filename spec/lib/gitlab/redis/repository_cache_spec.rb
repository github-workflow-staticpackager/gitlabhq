# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RepositoryCache, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'repository_cache', Gitlab::Redis::Cache
  include_examples "multi_store_wrapper_shared_examples"

  describe '.cache_store' do
    it 'has a default ttl of 8 hours' do
      expect(described_class.cache_store.options[:expires_in]).to eq(8.hours)
    end

    it 'uses a pool of multistore connections' do
      expect(described_class.cache_store.redis.checkout).to be_an_instance_of(Gitlab::Redis::MultiStore)
    end
  end

  it 'migrates from self to ClusterRepositoryCache' do
    expect(described_class.multistore.secondary_pool).to eq(described_class.pool)
    expect(described_class.multistore.primary_pool).to eq(Gitlab::Redis::ClusterRepositoryCache.pool)
  end
end
