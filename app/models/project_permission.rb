class ProjectPermission < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :auth_role
  has_many :project_permissions, through: :project

  validates :user_id, presence: true, uniqueness: {scope: :project_id}
  validates :project_id, presence: true
  validates :auth_role_id, presence: true
end
