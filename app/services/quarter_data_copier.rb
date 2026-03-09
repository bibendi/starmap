# Service for copying data from previous quarter to new quarter
class QuarterDataCopier
  def initialize(new_quarter, previous_quarter)
    @new_quarter = new_quarter
    @previous_quarter = previous_quarter
  end

  def copy_from_previous
    return true unless @previous_quarter

    copy_skill_ratings
    true
  rescue => e
    Rails.logger.error("Failed to copy quarter data: #{e.message}")
    false
  end

  private

  def copy_skill_ratings
    @previous_quarter.skill_ratings.find_each do |rating|
      @new_quarter.skill_ratings.create!(
        user: rating.user,
        team: rating.team,
        technology: rating.technology,
        rating: rating.rating,
        status: :draft
      )
    end
  end
end
