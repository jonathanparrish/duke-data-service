require 'rails_helper'

describe "db:data:migrate" do
  include_context "rake"
  let(:task_path) { "lib/tasks/db_data_migrate" }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:file_version_audits) { Audited.audit_class.where(auditable: FileVersion.all) }
  let(:data_file_audits) { Audited.audit_class.where(auditable: DataFile.all) }

  it { expect(subject.prerequisites).to  include("environment") }

  describe "#invoke" do

    context 'with correct current_versions' do
      before do
        Audited.audit_class.as_user(current_user) do
          FactoryGirl.create(:data_file)
          f = FactoryGirl.create(:data_file)
          f.upload = FactoryGirl.create(:upload, :completed, :with_fingerprint)
          f.save
        end
      end

      it { expect(file_version_audits).to all(satisfy('have user set') {|v| v.user }) }
      it { expect(data_file_audits).to all(satisfy('have user set') {|v| v.user }) }
      it { expect {invoke_task}.to change{FileVersion.count}.by(0) }
      it { expect {invoke_task}.to change{Audited.audit_class.count}.by(0) }
    end
    context 'without file_versions' do
      before do
        Audited.audit_class.as_user(current_user) do
          FactoryGirl.create(:data_file)
          FileVersion.last.destroy
        end
      end

      it { expect(file_version_audits).to all(satisfy('have user set') {|v| v.user }) }
      it { expect(data_file_audits).to all(satisfy('have user set') {|v| v.user }) }
      it { expect {invoke_task}.to change{FileVersion.count}.by(1) }
      it { expect {invoke_task}.to change{Audited.audit_class.count}.by(1) }

      context 'once called' do
        before { invoke_task }
        it { expect(file_version_audits).to all(satisfy('have user set to current_user') {|v| v.user == current_user }) }
      end
    end
    context 'with current_file_version upload mismatch' do
      before do
        Audited.audit_class.as_user(current_user) do
          FactoryGirl.create(:data_file)
          FileVersion.last.update_attribute(:upload, FactoryGirl.create(:upload, :completed, :with_fingerprint))
        end
      end

      it { expect(file_version_audits).to all(satisfy('have user set') {|v| v.user }) }
      it { expect(data_file_audits).to all(satisfy('have user set') {|v| v.user }) }
      it { expect {invoke_task}.to change{FileVersion.count}.by(1) }
      it { expect {invoke_task}.to change{Audited.audit_class.count}.by(1) }

      context 'once called' do
        before { invoke_task }
        it { expect(file_version_audits).to all(satisfy('have user set to current_user') {|v| v.user == current_user }) }
      end
    end

    context 'when creating fingerprints' do
      let(:fingerprint_upload) { FactoryGirl.create(:fingerprint).upload }
      let(:incomplete_upload_with_fingerprint_value) { FactoryGirl.create(:upload, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5') }
      let(:upload_with_fingerprint_value) { FactoryGirl.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5') }
      let(:upload_with_capitalized_algorithm) { FactoryGirl.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'MD5') }
      let(:upload_with_invalid_fingerprint_algorithm) { FactoryGirl.create(:upload, :completed, :skip_validation, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5000') }
      context 'for upload without fingerprint_value' do
        before { FactoryGirl.create(:upload) }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
      context 'for incomplete upload with fingerprint_value' do
        before { expect(incomplete_upload_with_fingerprint_value).to be_persisted }
        it { invoke_task(expected_stdout: /Creating fingerprints for 0 uploads/) }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(0) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(0) }
      end
      context 'for upload with fingerprint_value' do
        before { expect(upload_with_fingerprint_value).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(1) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(1) }
      end
      context 'for upload with capitalized algorithm' do
        before { expect(upload_with_capitalized_algorithm).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(1) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(1) }
      end
      context 'for upload with invalid fingerprint_algorithm' do
        before { expect(upload_with_invalid_fingerprint_algorithm).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(0) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(0) }
      end
      context 'for upload with associated fingerprint' do
        before { expect(fingerprint_upload).to be_persisted }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
      context 'for upload with associated fingerprint and fingerprint_value' do
        let(:fingerprint) { FactoryGirl.create(:fingerprint, upload: upload_with_fingerprint_value) }
        before { expect(fingerprint).to be_persisted }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
    end

    context 'without any untyped authentication services' do
      let(:duke_authentication_service) { FactoryGirl.create(:duke_authentication_service) }
      let(:openid_authentication_service) { FactoryGirl.create(:openid_authentication_service) }

      it {
        expect {
          invoke_task expected_stderr: /0 untyped authentication_services changed/
        }.not_to change{
          AuthenticationService.where(type: nil).count
        }
      }
    end

    context 'with untyped authentication services' do
      let(:default_type) { DukeAuthenticationService }
      let(:untyped_authentication_service) {
        AuthenticationService.create(FactoryGirl.attributes_for(:duke_authentication_service))
      }
      let(:openid_authentication_service) { FactoryGirl.create(:openid_authentication_service) }

      it {
        expect(untyped_authentication_service).not_to be_a default_type
        expect {
          invoke_task expected_stderr: Regexp.new("1 untyped authentication_services changed to #{default_type}")
        }.to change{
          AuthenticationService.where(type: nil).count
        }.by(-1)
        expected_to_be_typed_auth_service = AuthenticationService.find(untyped_authentication_service.id)
        expect(expected_to_be_typed_auth_service).to be_a default_type
        openid_authentication_service.reload
        expect(openid_authentication_service).to be_a OpenidAuthenticationService
      }
    end
  end

  context 'authentication_service required attributes' do
    let(:authentication_service) { FactoryGirl.create(:duke_authentication_service) }
    let(:missing_attributes) { %w(
      login_initiation_uri
      login_response_type
      client_id
    )}

    before do
      ENV["AUTH_SERVICE_SERVICE_ID"] = authentication_service.service_id
    end

    context 'missing ENV[AUTH_SERVICE_SERVICE_ID]' do
      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = nil
      end

      it {
        expect {
          invoke_task
        }.not_to raise_error
      }
    end

    context 'specified service does not exist' do
      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = SecureRandom.uuid
      end
      it {
        expect {
          invoke_task expected_stderr: /AUTH_SERVICE_SERVICE_ID is not a registered service/
        }.to raise_error(StandardError)
      }
    end

    context 'new attrbutes already populated' do
      before do
        missing_attributes.each do |invalid_attribute|
          ENV["AUTH_SERVICE_#{invalid_attribute.upcase}"] = authentication_service.send(invalid_attribute)
        end
      end
      it {
        invoke_task expected_stderr: Regexp.new("authentication_service #{ENV["AUTH_SERVICE_SERVICE_ID"]} attributes do not need to be updated")
      }
    end

    context 'one or more new attributes not populated' do
      before do
        missing_attributes.each do |invalid_attribute|
          ENV["AUTH_SERVICE_#{invalid_attribute.upcase}"] = authentication_service.send(invalid_attribute)
          authentication_service.update_attribute(invalid_attribute, nil)
        end
      end

      it {
        expect {
          invoke_task expected_stderr: Regexp.new("authentication_service #{ENV["AUTH_SERVICE_SERVICE_ID"]} missing_attributes updated")
        }.to change{
          AuthenticationService.where(
            AuthenticationService.unscoped.where(
              Hash[missing_attributes.map{ |a| [a, nil] }]
            ).where_values.reduce(:or)
          ).count
        }.by(-1)
        authentication_service.reload
        missing_attributes.each do |invalid_attribute|
          expect(authentication_service.send(invalid_attribute)).not_to be_nil
          expect(authentication_service.send(invalid_attribute)).to eq(ENV["AUTH_SERVICE_#{invalid_attribute.to_s.upcase}"])
        end
      }
    end
  end
end
