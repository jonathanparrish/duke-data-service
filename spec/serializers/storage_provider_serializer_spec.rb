require 'rails_helper'

RSpec.describe StorageProviderSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:storage_provider) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.display_name,
    'description' => resource.description,
    'is_deprecated' => resource.is_deprecated,
    'chunk_hash_algorithm' => resource.chunk_hash_algorithm
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
