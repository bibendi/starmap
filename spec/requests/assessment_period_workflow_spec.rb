require "rails_helper"

RSpec.describe "Assessment period workflow", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:team) { create(:team) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:lead) { create(:team_lead, team: team) }
  let_it_be(:technology) { create(:technology) }
  let_it_be(:team_technology) { create(:team_technology, team: team, technology: technology, target_experts: 1) }
  let_it_be(:previous) { create(:assessment_period, :closed, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 3, 31)) }

  before do
    create(:skill_rating, user: engineer, team: team, technology: technology, assessment_period: previous, rating: 2, status: :approved)
  end

  it "preserves copying, self-assessment, approvals and metrics through monthly and custom periods" do
    sign_in admin
    post admin_assessment_periods_path, params: {assessment_period: {
      period_kind: "monthly", calendar_year: 2026, calendar_number: 4,
      evaluation_start_date: "2026-05-01", evaluation_end_date: "2026-05-15"
    }}
    expect(response).to redirect_to(admin_assessment_periods_path)
    monthly = AssessmentPeriod.ordered.last
    post activate_admin_assessment_period_path(monthly)
    expect(monthly.reload).to be_active
    expect(monthly.skill_ratings.find_by!(user: engineer).rating).to eq(2)

    sign_out admin
    sign_in engineer
    travel_to Date.new(2026, 5, 2) do
      patch user_skill_ratings_path(engineer), params: {ratings: {technology.id => {rating: 3}}}
      expect(response).to redirect_to(user_skill_ratings_path(engineer))
      post submit_user_skill_ratings_path(engineer)
      expect(monthly.skill_ratings.find_by!(user: engineer)).to be_submitted
    end
    sign_out engineer
    sign_in lead
    post approve_all_user_skill_ratings_path(engineer)
    expect(monthly.skill_ratings.find_by!(user: engineer)).to be_approved
    expect(UserRatingChangesQuery.new(user: engineer, assessment_period: monthly).changes_by_technology).to eq(technology.id => 1)
    expect(CoverageIndexQuery.new(teams: [team], assessment_period: monthly).percentage).to eq(100)

    sign_out lead
    sign_in admin
    post close_admin_assessment_period_path(monthly)
    post admin_assessment_periods_path, params: {assessment_period: {
      period_kind: "custom", start_date: "2026-05-15", end_date: "2026-06-20",
      evaluation_start_date: "2026-06-21", evaluation_end_date: "2026-07-05"
    }}
    custom = AssessmentPeriod.ordered.last
    post activate_admin_assessment_period_path(custom)
    expect(custom.previous_assessment_period).to eq(monthly)
    expect(custom.reload).to be_active
    expect(custom.skill_ratings.find_by!(user: engineer).rating).to eq(3)
    expect(AssessmentPeriod.current).to eq(custom)
    expect(CoverageIndexHistoryQuery.new(teams: [team]).data.pluck(:period_name)).to eq([previous.full_name, monthly.full_name, custom.full_name])
  end

  it "removes old routes and does not translate the old quarter parameter" do
    expect { Rails.application.routes.recognize_path("/admin/quarters", method: :get) }.to raise_error(ActionController::RoutingError)
    sign_in admin
    expect do
      post admin_assessment_periods_path, params: {quarter: {year: 2027, quarter_number: 1}}
    end.not_to change(AssessmentPeriod, :count)
    expect(response).to have_http_status(:bad_request)
  end

  %w[en ru].each do |locale|
    it "renders all types and the form in #{locale} for either theme" do
      sign_in admin
      post switch_locale_path(locale: locale)
      %w[light dark].each do |theme|
        post switch_theme_path(theme: theme)
        get new_admin_assessment_period_path
        expect(response).to be_successful
        expect(response.body).to include("assessment_period[period_kind]", "assessment_period[calendar_year]")
        expect(response.body).not_to include("Translation missing", "quarter[", "assessment_period[quarter_number]")
        AssessmentPeriod.period_kinds.each_key do |kind|
          expect(response.body).to include(I18n.t("admin.assessment_periods.kinds.#{kind}", locale: locale))
        end
      end
    end
  end
end
