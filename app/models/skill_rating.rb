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
  validates :user_id, uniqueness: {scope: [:technology_id, :quarter_id], message: "уже имеет оценку для этой технологии в данном квартале"}

  before_validation :set_team_from_user, if: -> { team_id.nil? && user_id.present? }

  scope :by_quarter, ->(quarter) { where(quarter: quarter) }
  scope :by_user, ->(user) { where(user: user) }

  def level
    case rating
    when 0 then "Не имею представления"
    when 1 then "Имею представление"
    when 2 then "Свободно владею"
    when 3 then "Могу учить других"
    else "Неизвестно"
    end
  end

  def can_be_submitted?
    draft?
  end

  def submit_for_approval
    update!(status: :submitted) if draft?
  end

  private

  def set_team_from_user
    self.team_id = user.team_id if user.present?
  end
end
