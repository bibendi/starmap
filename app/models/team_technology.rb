class TeamTechnology < ApplicationRecord
  belongs_to :team
  belongs_to :technology

  enum :status, {active: "active", archived: "archived"}, default: "active"

  validates :criticality, presence: true, inclusion: {in: %w[high normal low]}
  validates :target_experts, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :technology_id, uniqueness: {scope: :team_id, message: :taken}

  scope :active, -> { where(status: "active") }
  scope :archived, -> { where(status: "archived") }
  scope :critical, -> { where(criticality: [:normal, :high]) }

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.criticality ||= technology&.criticality
    self.target_experts ||= technology&.target_experts
  end
end
