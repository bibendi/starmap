# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamSkillMatrixComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active, is_current: true) }
  let_it_be(:previous_quarter) { create(:quarter, :previous, :closed, relative_to: current_quarter) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology, name: "Ruby", category: "Backend") }
  let_it_be(:technology2) { create(:technology, name: "React", category: "Frontend") }
  let_it_be(:technology3) { create(:technology, name: "PostgreSQL", category: "Database") }

  before do
    create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: :high)
    create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: :normal)
    create(:team_technology, team: team, technology: technology3, target_experts: 1, criticality: :low)
  end

  describe "#initialize" do
    it "initializes with a team" do
      component = described_class.new(team: team)
      expect(component.team).to eq(team)
    end

    it "sets team_members" do
      component = described_class.new(team: team)
      expect(component.team_members).to include(user1, user2)
    end

    it "sets technologies" do
      component = described_class.new(team: team)
      expect(component.technologies).to include(technology1, technology2, technology3)
    end
  end

  describe "#any_data?" do
    context "when team has no members" do
      let(:empty_team) { create(:team) }

      it "returns false" do
        component = described_class.new(team: empty_team)
        expect(component.any_data?).to be false
      end
    end

    context "when team has members but no skill ratings" do
      it "returns false" do
        component = described_class.new(team: team)
        expect(component.any_data?).to be false
      end
    end

    context "when team has members and skill ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns true" do
        component = described_class.new(team: team)
        expect(component.any_data?).to be true
      end
    end
  end

  describe "#rating_for" do
    before do
      create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
    end

    it "returns the rating for a user and technology" do
      component = described_class.new(team: team)
      expect(component.rating_for(technology1.id, user1.id)).to eq(2)
    end

    it "returns 0 when no rating exists" do
      component = described_class.new(team: team)
      expect(component.rating_for(technology2.id, user1.id)).to eq(0)
    end
  end

  describe "#change_for" do
    context "when there is a change" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns the change in rating" do
        component = described_class.new(team: team)
        expect(component.change_for(technology1.id, user1.id)).to eq(1)
      end
    end

    context "when there is no change" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns nil" do
        component = described_class.new(team: team)
        expect(component.change_for(technology1.id, user1.id)).to be_nil
      end
    end
  end

  describe "#bus_factor_for" do
    context "when technology has no experts" do
      it "returns high risk level" do
        component = described_class.new(team: team)
        bus_factor = component.bus_factor_for(technology1.id)
        expect(bus_factor[:risk_level]).to eq('high')
        expect(bus_factor[:count]).to eq(0)
      end
    end

    context "when technology has insufficient experts" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns medium risk level" do
        component = described_class.new(team: team)
        bus_factor = component.bus_factor_for(technology1.id)
        expect(bus_factor[:risk_level]).to eq('medium')
        expect(bus_factor[:count]).to eq(1)
      end
    end

    context "when technology has sufficient experts" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns low risk level" do
        component = described_class.new(team: team)
        bus_factor = component.bus_factor_for(technology1.id)
        expect(bus_factor[:risk_level]).to eq('low')
        expect(bus_factor[:count]).to eq(2)
      end
    end

    context "when there is a change from previous quarter" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns the change in expert count" do
        component = described_class.new(team: team)
        bus_factor = component.bus_factor_for(technology1.id)
        expect(bus_factor[:change]).to eq(1)
      end
    end
  end

  describe "rendering" do
    context "when there is no data" do
      it "renders empty state message" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Нет данных о навыках команды.")
      end
    end

    context "when there is data" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 1, team: team)
      end

      it "renders the table header" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Технология")
        expect(page).to have_text("Bus Factor")
      end

      it "renders technology names" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Ruby")
        expect(page).to have_text("React")
      end

      it "renders user first names" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text(user1.full_name.split.first)
        expect(page).to have_text(user2.full_name.split.first)
      end

      it "renders ratings" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("2")
        expect(page).to have_text("3")
        expect(page).to have_text("1")
      end

      it "renders the legend" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Может учить других")
        expect(page).to have_text("Свободно владеет")
        expect(page).to have_text("Имеет представление")
        expect(page).to have_text("Не владеет")
      end
    end

    context "when there is rating dynamics" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders the change indicator" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("+1")
      end
    end

    context "when there is no previous quarter" do
      let(:single_quarter) { create(:quarter, status: :active, is_current: true) }

      before do
        Quarter.where.not(id: single_quarter.id).delete_all
        create(:skill_rating, user: user1, technology: technology1, quarter: single_quarter, rating: 2, team: team)
      end

      it "does not render change indicators" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).not_to have_selector(".change-indicator")
      end
    end

    context "when there are no changes from previous quarter" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "does not render change indicators" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).not_to have_selector(".change-indicator")
      end
    end

    context "when technology has criticality badges" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders high criticality badge" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("High")
      end

      it "renders normal criticality badge" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Norm")
      end

      it "renders low criticality badge" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Low")
      end
    end

    context "when technology has bus factor risk levels" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders medium risk level" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("1/2")
      end
    end
  end
end
