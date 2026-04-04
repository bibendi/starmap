class TeamTechnology < ApplicationRecord
  # Associations
  belongs_to :team
  belongs_to :technology

  # Validations
  validates :criticality, presence: true, inclusion: {in: %w[high normal low]}
  validates :target_experts, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :technology_id, uniqueness: {scope: :team_id, message: :taken}

  # Scopes
  scope :high_criticality, -> { where(criticality: "high") }
  scope :normal_criticality, -> { where(criticality: "normal") }
  scope :low_criticality, -> { where(criticality: "low") }

  # Callbacks
  before_validation :set_defaults, on: :create

  # Criticality helpers
  def high_criticality?
    criticality == "high"
  end

  def normal_criticality?
    criticality == "normal"
  end

  def low_criticality?
    criticality == "low"
  end

  def criticality_label
    case criticality
    when "high" then "Высокая"
    when "normal" then "Обычная"
    when "low" then "Низкая"
    else criticality
    end
  end

  private

  def set_defaults
    self.criticality ||= technology&.criticality || "normal"
    self.target_experts ||= self.class.default_target_experts_for(criticality)
  end

  class << self
    def default_target_experts_for(criticality)
      case criticality
      when "high" then 3
      when "normal" then 2
      when "low" then 1
      else 2
      end
    end
  end
end
