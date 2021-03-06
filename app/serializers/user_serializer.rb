class UserSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id,
             :username,
             :full_name,
             :first_name,
             :last_name,
             :email,
             :auth_provider,
             :last_login_on,
             :audit

  has_one :current_software_agent, root: :agent, serializer: SoftwareAgentPreviewSerializer

  def last_login_on
    object.last_login_at
  end

  def full_name
    object.display_name
  end

  def auth_provider
    UserAuthenticationServiceSerializer.new(object.user_authentication_services.first)
  end
end
