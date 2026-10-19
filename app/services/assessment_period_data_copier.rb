# Service for copying data from previous assessment_period to new assessment_period
class AssessmentPeriodDataCopier
  def initialize(new_assessment_period, previous_assessment_period)
    @new_assessment_period = new_assessment_period
    @previous_assessment_period = previous_assessment_period
  end

  def copy_from_previous
    return true unless @previous_assessment_period

    AssessmentPeriod.transaction(requires_new: true) { copy_skill_ratings }
    true
  rescue => e
    Rails.logger.error("Failed to copy assessment_period data: #{e.message}")
    false
  end

  private

  def copy_skill_ratings
    @previous_assessment_period.skill_ratings.includes(:user).find_each do |rating|
      next unless rating.user.team_id == rating.team_id

      @new_assessment_period.skill_ratings.create!(
        user: rating.user,
        team: rating.team,
        technology: rating.technology,
        rating: rating.rating,
        status: :draft
      )
    end
  end
end
