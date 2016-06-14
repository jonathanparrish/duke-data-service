class Tag < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  audited

  belongs_to :taggable, polymorphic: true

  validates :label, presence: true
  validates :taggable, presence: true

  def project_permissions
    taggable.project_permissions
  end

  def self.label_like(label_contains) 
    where("label LIKE ?", "%#{label_contains}%")
  end

  def self.label_count
    unscope(:order).select(:label).group(:label).count.collect do |l|
      TagLabel.new(label: l.first, count: l.second)
    end
  end
end
