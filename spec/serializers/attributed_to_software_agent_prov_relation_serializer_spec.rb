require 'rails_helper'
RSpec.describe AttributedToSoftwareAgentProvRelationSerializer, type: :serializer do
  let(:software_agent) { FactoryGirl.create(:software_agent) }
  let(:resource) { FactoryGirl.create(:attributed_to_software_agent_prov_relation,
    relatable_to: software_agent) }
  it_behaves_like 'a ProvRelationSerializer', from: FileVersionSerializer, to: SoftwareAgentSerializer
end
