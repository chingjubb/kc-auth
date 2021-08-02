require_relative "../../../lib/kc/cache/memory_cache"
require_relative "./cache_base_spec"

RSpec.describe Kc::Cache::MemoryCache do
  let(:cache) { described_class.new }

  it_behaves_like "CacheBase"
end
