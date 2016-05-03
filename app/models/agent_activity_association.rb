class AgentActivityAssociation < ActiveRecord::Base
  include Graphed
  after_create :graph_relation
  after_destroy :delete_graph_relation

  audited

  belongs_to :agent, polymorphic: true
  belongs_to :activity

  validates :agent, presence: true
  validates :agent_type, inclusion: { in: %w(User SoftwareAgent),
    message: "Agent must be a User or a SoftwareAgent" }

  validates :activity, presence: true

  def graph_relation
    super('WasAssociatedWith', agent, activity)
  end
end