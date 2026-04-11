# frozen_string_literal: true

class Technology < ApplicationRecord
  DEFAULT_TARGET_EXPERTS = 2
  DEFAULT_CRITICALITY = "normal"

  belongs_to :category, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :skill_ratings, dependent: :restrict_with_error
  has_many :users, through: :skill_ratings
  has_many :team_technologies, dependent: :restrict_with_error
  has_many :teams, through: :team_technologies

  validates :name, presence: true, uniqueness: true
  validates :criticality, presence: true, inclusion: {in: %w[high normal low]}
  validates :target_experts, numericality: {only_integer: true, greater_than: 0}
  validates :sort_order, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  before_validation :set_default_values, on: :create

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }

  private

  def set_default_values
    self.criticality ||= DEFAULT_CRITICALITY
    self.target_experts ||= DEFAULT_TARGET_EXPERTS
    self.sort_order ||= Technology.maximum(:sort_order).to_i + 1
  end
end
