# frozen_string_literal: true

class SkillRating < ApplicationRecord
  belongs_to :user, inverse_of: :skill_ratings
  belongs_to :technology
  belongs_to :quarter
  belongs_to :team
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  enum :status, {draft: "draft", submitted: "submitted", approved: "approved", rejected: "rejected"}, default: :draft

  validates :rating, presence: true, inclusion: {in: 0..3}
  validates :user_id, uniqueness: {scope: [:technology_id, :quarter_id]}

  before_validation :set_team_from_user, if: -> { team_id.nil? && user_id.present? }

  scope :by_quarter, ->(quarter) { where(quarter: quarter) }
  scope :by_user, ->(user) { where(user: user) }

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
