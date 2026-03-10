# Service for managing quarter status transitions
class QuarterStatusService
  attr_reader :errors

  def initialize(quarter, user)
    @quarter = quarter
    @user = user
    @errors = []
  end

  # Activate a draft quarter
  def activate
    return false unless validate_can_activate

    Quarter.transaction do
      deactivate_current_quarter if current_quarter_exists?
      @quarter.update!(
        status: :active,
        is_current: true
      )
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  # Close an active quarter
  def close
    return false unless validate_can_close

    Quarter.transaction do
      @quarter.update!(status: :closed)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  # Archive a closed quarter
  def archive
    return false unless validate_can_archive

    Quarter.transaction do
      @quarter.update!(status: :archived)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  private

  def validate_can_activate
    if !@quarter.draft?
      @errors << I18n.t("admin.quarters.errors.not_draft")
      return false
    end

    if any_active_quarter_exists?
      @errors << I18n.t("admin.quarters.errors.active_exists")
      return false
    end

    true
  end

  def validate_can_close
    if !@quarter.active?
      @errors << I18n.t("admin.quarters.errors.not_active")
      return false
    end

    true
  end

  def validate_can_archive
    if !@quarter.closed?
      @errors << I18n.t("admin.quarters.errors.not_closed")
      return false
    end

    true
  end

  def any_active_quarter_exists?
    Quarter.where(status: :active).where.not(id: @quarter.id).exists?
  end

  def current_quarter_exists?
    Quarter.where(is_current: true).where.not(id: @quarter.id).exists?
  end

  def deactivate_current_quarter
    Quarter.where(is_current: true).update_all(is_current: false)
  end
end
