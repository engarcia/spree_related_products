class Spree::Relation < ActiveRecord::Base
  belongs_to :relation_type
  belongs_to :relatable, polymorphic: true, touch: true
  belongs_to :related_to, polymorphic: true

  validates :relation_type, :relatable, :related_to, presence: true

  validates :relatable_id, uniqueness: { scope: [:related_to_id, :relation_type_id] }
end
