# frozen_string_literal: true

class SkillRating < ApplicationRecord
  belongs_to :user, inverse_of: :skill_ratings
  belongs_to :technology
  belongs_to :assessment_period
  belongs_to :team
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  ALL_STATUSES = %w[draft submitted approved rejected].freeze
  APPROVED_ONLY_STATUSES = %w[approved].freeze

  enum :status, {draft: "draft", submitted: "submitted", approved: "approved", rejected: "rejected"}, default: :draft

  validates :rating, presence: true, inclusion: {in: 0..3}
  validates :user_id, uniqueness: {scope: [:technology_id, :assessment_period_id]}

  before_validation :set_team_from_user, if: -> { team_id.nil? && user_id.present? }

  EXPERT_MIN_RATING = 2
  EXPERT_MAX_RATING = 3

  scope :by_assessment_period, ->(assessment_period) { where(assessment_period: assessment_period) }
  scope :by_user, ->(user) { where(user: user) }
  scope :expert_ratings, -> { where(rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING) }
  scope :visible_for_assessment_period, ->(assessment_period) { where(status: statuses_visible_for(assessment_period)) }
  scope :visible_for_assessment_periods, ->(assessment_periods) {
    return none if assessment_periods.blank?

    current, others = assessment_periods.partition(&:is_current?)
    conditions = []
    conditions << where(assessment_period: current, status: ALL_STATUSES) if current.any?
    conditions << where(assessment_period: others, status: APPROVED_ONLY_STATUSES) if others.any?
    conditions.reduce(:or) || none
  }

  def self.statuses_visible_for(assessment_period)
    assessment_period&.is_current? ? ALL_STATUSES : APPROVED_ONLY_STATUSES
  end

  def can_be_submitted?
    draft?
  end

  def submit_for_approval
    update!(status: :submitted) if draft?
  end

  def approve!(approver)
    raise ActiveRecord::RecordInvalid, self unless submitted?

    update!(status: :approved, approved_by: approver, approved_at: Time.current)
  end

  def reject!(approver)
    raise ActiveRecord::RecordInvalid, self unless submitted?

    update!(status: :rejected, approved_by: approver, approved_at: Time.current)
  end

  private

  def set_team_from_user
    self.team_id = user.team_id if user.present?
  end
end
