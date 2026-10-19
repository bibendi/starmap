# Service for managing assessment_period status transitions
class AssessmentPeriodStatusService
  attr_reader :errors

  def initialize(assessment_period, user)
    @assessment_period = assessment_period
    @user = user
    @errors = []
  end

  # Activate a draft assessment_period
  def activate
    return false unless validate_can_activate

    AssessmentPeriod.transaction do
      deactivate_current_assessment_period if current_assessment_period_exists?
      @assessment_period.update!(
        status: :active,
        is_current: true
      )
      copy_previous_assessment_period_ratings
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    @errors << e.message
    false
  end

  # Close an active assessment_period
  def close
    return false unless validate_can_close

    AssessmentPeriod.transaction do
      @assessment_period.update!(status: :closed)
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    @errors << e.message
    false
  end

  # Archive a closed assessment_period
  def archive
    return false unless validate_can_archive

    AssessmentPeriod.transaction do
      @assessment_period.update!(status: :archived)
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    @errors << e.message
    false
  end

  private

  def validate_can_activate
    if !@assessment_period.draft?
      @errors << I18n.t("admin.assessment_periods.errors.not_draft")
      return false
    end

    if any_active_assessment_period_exists?
      @errors << I18n.t("admin.assessment_periods.errors.active_exists")
      return false
    end

    true
  end

  def validate_can_close
    if !@assessment_period.active?
      @errors << I18n.t("admin.assessment_periods.errors.not_active")
      return false
    end

    true
  end

  def validate_can_archive
    if !@assessment_period.closed?
      @errors << I18n.t("admin.assessment_periods.errors.not_closed")
      return false
    end

    true
  end

  def any_active_assessment_period_exists?
    AssessmentPeriod.where(status: :active).where.not(id: @assessment_period.id).exists?
  end

  def current_assessment_period_exists?
    AssessmentPeriod.where(is_current: true).where.not(id: @assessment_period.id).exists?
  end

  def deactivate_current_assessment_period
    AssessmentPeriod.where(is_current: true).update_all(is_current: false)
  end

  def copy_previous_assessment_period_ratings
    previous = @assessment_period.previous_assessment_period
    return unless previous

    return if AssessmentPeriodDataCopier.new(@assessment_period, previous).copy_from_previous

    raise ActiveRecord::RecordInvalid, @assessment_period
  end
end
