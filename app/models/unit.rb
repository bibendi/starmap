class Unit < ApplicationRecord
  has_many :teams, dependent: :restrict_with_error
  belongs_to :unit_lead, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def to_s
    name
  end
end
