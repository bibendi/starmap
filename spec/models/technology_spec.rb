require "rails_helper"

RSpec.describe Technology, type: :model do
  describe "associations" do
    it "belongs to category" do
      category = create(:category, name: "Backend")
      technology = build(:technology, category: category)

      expect(technology.category).to eq(category)
      expect(technology.category_id).to eq(category.id)
    end

    it "allows nil category" do
      technology = build(:technology, category: nil)

      expect(technology.category).to be_nil
    end
  end

  describe "#category_name" do
    it "returns category name via association" do
      category = build(:category, name: "Backend")
      technology = build(:technology, category: category)

      expect(technology.category&.name).to eq("Backend")
    end

    it "returns nil when no category" do
      technology = build(:technology, category: nil)

      expect(technology.category).to be_nil
    end
  end
end
