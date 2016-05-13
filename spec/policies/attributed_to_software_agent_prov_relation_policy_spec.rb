require 'rails_helper'

describe AttributedToSoftwareAgentProvRelationPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:user) { project_permission.user }
  let(:users_sa) { FactoryGirl.create(:software_agent, creator: user) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project_permission.project) }
  let(:users_file_version) { FactoryGirl.create(:file_version, data_file: data_file) }

  let(:other_users_file_version) { FactoryGirl.create(:file_version) }
  let(:other_file_version_creator) { other_users_file_version.data_file.upload.creator }
  let(:other_users_sa) { FactoryGirl.create(:software_agent, creator: other_file_version_creator) }

  context 'destroy' do
    let(:prov_relation) { FactoryGirl.create(:attributed_to_software_agent_prov_relation,
      relatable_to: users_sa,
      creator: user,
      relatable_from: users_file_version)
    }
    let(:other_prov_relation) {
      FactoryGirl.create(:attributed_to_software_agent_prov_relation)
    }
    it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:destroy?]
    it_behaves_like 'a policy for', :user, on: :other_prov_relation, allows: [], denies: [:show?, :create?, :index?, :update?, :destroy?]
  end

  context 'file_version visible by user' do
    context 'with a software agent that they created' do
      let(:prov_relation) { FactoryGirl.create(:attributed_to_software_agent_prov_relation,
        relatable_to: users_sa,
        relatable_from: users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
      it_behaves_like 'a user with project_permission', :view_project, allows: [:show?, :create?], on: :prov_relation
      it_behaves_like 'a user without project_permission', :view_project, denies: [:show?, :create?], on: :prov_relation
    end

    context 'with a software agent created by another user' do
      let(:prov_relation) { FactoryGirl.create(:attributed_to_software_agent_prov_relation,
        relatable_to: other_users_sa,
        relatable_from: users_file_version)
       }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
      it_behaves_like 'a user with project_permission', :view_project, allows: [:show?, :create?], on: :prov_relation
      it_behaves_like 'a user without project_permission', :view_project, denies: [:show?, :create?], on: :prov_relation
    end
  end

  context 'file_version not visible to user' do
    context 'with a software_agent created by the user' do
      let(:prov_relation) {
        FactoryGirl.create(:attributed_to_software_agent_prov_relation,
          relatable_to: users_sa,
          relatable_from: other_users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
      it_behaves_like 'a user with project_permission', :view_project, allows: [], on: :prov_relation
      it_behaves_like 'a user without project_permission', :view_project, denies: [:show?, :create?, :destroy?], on: :prov_relation
    end

    context 'with a software_agent created by other user' do
      let(:prov_relation) {
        FactoryGirl.create(:attributed_to_software_agent_prov_relation,
          relatable_to: other_users_sa,
          relatable_from: other_users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
      it_behaves_like 'a user with project_permission', :view_project, allows: [], on: :prov_relation
      it_behaves_like 'a user without project_permission', :view_project, denies: [:show?, :create?, :destroy?], on: :prov_relation
    end
  end
end
