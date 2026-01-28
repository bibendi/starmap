# Unit model for grouping teams
class Unit < ApplicationRecord
  # Associations
  has_many :teams, dependent: :nullify
  belongs_to :unit_lead, class_name: "User", optional: true

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :sort_order, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }

  # Callbacks
  before_validation :set_default_sort_order, on: :create

  # Methods
  def to_s
    name
  end

  private

  def set_default_sort_order
    self.sort_order ||= Unit.maximum(:sort_order).to_i + 1
  end
end
