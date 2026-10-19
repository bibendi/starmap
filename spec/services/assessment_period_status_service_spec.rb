require "rails_helper"

RSpec.describe AssessmentPeriodStatusService, type: :service do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:draft_assessment_period) { create(:assessment_period, status: :draft) }
  let_it_be(:closed_assessment_period) { create(:assessment_period, status: :closed) }

  describe "#activate" do
    context "when assessment_period is in draft status" do
      it "transitions assessment_period to active status" do
        service = described_class.new(draft_assessment_period, admin)
        result = service.activate

        expect(result).to be true
        expect(draft_assessment_period.reload.status).to eq "active"
      end

      it "sets assessment_period as current" do
        service = described_class.new(draft_assessment_period, admin)
        service.activate

        expect(draft_assessment_period.reload.is_current).to be true
      end

      it "copies ratings from previous assessment_period" do
        previous = create(:assessment_period, status: :closed, is_current: false, year: draft_assessment_period.start_date.year - 1)
        create(:skill_rating, assessment_period: previous, rating: 2, status: :approved)

        allow(draft_assessment_period).to receive(:previous_assessment_period).and_return(previous)
        copier = instance_double(AssessmentPeriodDataCopier)
        allow(AssessmentPeriodDataCopier).to receive(:new).with(draft_assessment_period, previous).and_return(copier)
        allow(copier).to receive(:copy_from_previous).and_return(true)

        service = described_class.new(draft_assessment_period, admin)
        service.activate

        expect(copier).to have_received(:copy_from_previous)
      end

      it "skips copying when no previous assessment_period exists" do
        allow(draft_assessment_period).to receive(:previous_assessment_period).and_return(nil)

        service = described_class.new(draft_assessment_period, admin)
        result = service.activate

        expect(result).to be true
      end

      context "when there is a closed current assessment_period" do
        let!(:closed_current_assessment_period) do
          create(:assessment_period, status: :closed, is_current: true, year: 2098, quarter_number: 4)
        end
        let(:new_draft_assessment_period) { create(:assessment_period, status: :draft, year: 2099, quarter_number: 1) }

        it "deactivates the closed current assessment_period" do
          service = described_class.new(new_draft_assessment_period, admin)
          result = service.activate

          expect(result).to be true
          expect(closed_current_assessment_period.reload.is_current).to be false
          expect(new_draft_assessment_period.reload.is_current).to be true
        end
      end
    end

    context "when assessment_period is not in draft status" do
      it "returns false and adds error" do
        service = described_class.new(closed_assessment_period, admin)
        result = service.activate

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end

    context "when there is already an active assessment_period" do
      before { create(:assessment_period, status: :active, is_current: true, year: 2099, quarter_number: 4) }

      it "returns false and adds error" do
        service = described_class.new(draft_assessment_period, admin)
        result = service.activate

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#close" do
    context "when assessment_period is in active status" do
      let(:active_assessment_period) { create(:assessment_period, status: :active, is_current: true, year: 2097, quarter_number: 2) }

      it "transitions assessment_period to closed status" do
        service = described_class.new(active_assessment_period, admin)
        result = service.close

        expect(result).to be true
        expect(active_assessment_period.reload.status).to eq "closed"
      end

      it "keeps current flag" do
        service = described_class.new(active_assessment_period, admin)
        service.close

        expect(active_assessment_period.reload.is_current).to be true
      end
    end

    context "when assessment_period is not in active status" do
      it "returns false and adds error" do
        service = described_class.new(draft_assessment_period, admin)
        result = service.close

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#archive" do
    context "when assessment_period is in closed status" do
      it "transitions assessment_period to archived status" do
        service = described_class.new(closed_assessment_period, admin)
        result = service.archive

        expect(result).to be true
        expect(closed_assessment_period.reload.status).to eq "archived"
      end
    end

    context "when assessment_period is not in closed status" do
      it "returns false and adds error" do
        service = described_class.new(draft_assessment_period, admin)
        result = service.archive

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#errors" do
    it "returns empty array initially" do
      service = described_class.new(draft_assessment_period, admin)
      expect(service.errors).to be_empty
    end
  end
end
