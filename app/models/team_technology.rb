class TeamTechnology < ApplicationRecord
  belongs_to :team
  belongs_to :technology

  validates :criticality, presence: true, inclusion: {in: %w[high normal low]}
  validates :target_experts, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :technology_id, uniqueness: {scope: :team_id, message: :taken}

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.criticality ||= technology&.criticality
    self.target_experts ||= technology&.target_experts
  end
end
