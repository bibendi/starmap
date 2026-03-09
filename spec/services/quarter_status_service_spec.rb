require "rails_helper"

RSpec.describe QuarterStatusService, type: :service do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:quarter) { create(:quarter, status: :draft) }

  describe "#activate" do
    context "when quarter is in draft status" do
      it "transitions quarter to active status" do
        service = described_class.new(quarter, admin)
        result = service.activate

        expect(result).to be true
        expect(quarter.reload.status).to eq "active"
      end

      it "sets quarter as current" do
        service = described_class.new(quarter, admin)
        service.activate

        expect(quarter.reload.is_current).to be true
      end
    end

    context "when quarter is not in draft status" do
      let(:quarter) { create(:quarter, status: :closed) }

      it "returns false and adds error" do
        service = described_class.new(quarter, admin)
        result = service.activate

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end

    context "when there is already an active quarter" do
      before do
        create(:quarter, status: :active, is_current: true)
      end

      it "returns false and adds error" do
        service = described_class.new(quarter, admin)
        result = service.activate

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#close" do
    let_it_be(:quarter) { create(:quarter, status: :active, is_current: true) }

    context "when quarter is in active status" do
      it "transitions quarter to closed status" do
        service = described_class.new(quarter, admin)
        result = service.close

        expect(result).to be true
        expect(quarter.reload.status).to eq "closed"
      end

      it "removes current flag" do
        service = described_class.new(quarter, admin)
        service.close

        expect(quarter.reload.is_current).to be false
      end
    end

    context "when quarter is not in active status" do
      let(:quarter) { create(:quarter, status: :draft) }

      it "returns false and adds error" do
        service = described_class.new(quarter, admin)
        result = service.close

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#archive" do
    let_it_be(:quarter) { create(:quarter, status: :closed) }

    context "when quarter is in closed status" do
      it "transitions quarter to archived status" do
        service = described_class.new(quarter, admin)
        result = service.archive

        expect(result).to be true
        expect(quarter.reload.status).to eq "archived"
      end
    end

    context "when quarter is not in closed status" do
      let(:quarter) { create(:quarter, status: :active) }

      it "returns false and adds error" do
        service = described_class.new(quarter, admin)
        result = service.archive

        expect(result).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe "#errors" do
    it "returns empty array initially" do
      service = described_class.new(quarter, admin)
      expect(service.errors).to be_empty
    end
  end
end
