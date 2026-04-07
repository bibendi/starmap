require "rails_helper"

RSpec.describe QuarterStatusService, type: :service do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:draft_quarter) { create(:quarter, status: :draft) }
  let_it_be(:closed_quarter) { create(:quarter, status: :closed) }

  describe "#activate" do
    context "when quarter is in draft status" do
      it "transitions quarter to active status" do
        service = described_class.new(draft_quarter, admin)
        result = service.activate

        expect(result).to be true
        expect(draft_quarter.reload.status).to eq "active"
      end

      it "sets quarter as current" do
        service = described_class.new(draft_quarter, admin)
        service.activate

        expect(draft_quarter.reload.is_current).to be true
      end

      context "when there is a closed current quarter" do
        let!(:closed_current_quarter) do
          create(:quarter, status: :closed, is_current: true)
        end
        let(:new_draft_quarter) { create(:quarter, status: :draft) }

        it "deactivates the closed current quarter" do
          service = described_class.new(new_draft_quarter, admin)
          result = service.activate

          expect(result).to be true
          expect(closed_current_quarter.reload.is_current).to be false
          expect(new_draft_quarter.reload.is_current).to be true
        end
      end
    end

    context "when quarter is not in draft status" do
      it "returns false and adds error" do
        service = described_class.new(closed_quarter, admin)
        result = service.activate

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end

    context "when there is already an active quarter" do
      before { create(:quarter, status: :active, is_current: true) }

      it "returns false and adds error" do
        service = described_class.new(draft_quarter, admin)
        result = service.activate

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#close" do
    context "when quarter is in active status" do
      let(:active_quarter) { create(:quarter, status: :active, is_current: true) }

      it "transitions quarter to closed status" do
        service = described_class.new(active_quarter, admin)
        result = service.close

        expect(result).to be true
        expect(active_quarter.reload.status).to eq "closed"
      end

      it "keeps current flag" do
        service = described_class.new(active_quarter, admin)
        service.close

        expect(active_quarter.reload.is_current).to be true
      end
    end

    context "when quarter is not in active status" do
      it "returns false and adds error" do
        service = described_class.new(draft_quarter, admin)
        result = service.close

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#archive" do
    context "when quarter is in closed status" do
      it "transitions quarter to archived status" do
        service = described_class.new(closed_quarter, admin)
        result = service.archive

        expect(result).to be true
        expect(closed_quarter.reload.status).to eq "archived"
      end
    end

    context "when quarter is not in closed status" do
      it "returns false and adds error" do
        service = described_class.new(draft_quarter, admin)
        result = service.archive

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#errors" do
    it "returns empty array initially" do
      service = described_class.new(draft_quarter, admin)
      expect(service.errors).to be_empty
    end
  end
end
