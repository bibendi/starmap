require "rails_helper"

RSpec.describe Category, type: :model do
  describe "validations" do
    it "requires name" do
      category = described_class.new(name: nil)
      category.valid?

      expect(category.errors[:name]).to include("can't be blank")
    end

    it "requires unique name" do
      create(:category, name: "Backend")
      category = described_class.new(name: "Backend")
      category.valid?

      expect(category.errors[:name]).to include("has already been taken")
    end

    it "requires case-insensitive unique name" do
      create(:category, name: "Backend")
      category = described_class.new(name: "backend")
      category.valid?

      expect(category.errors[:name]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "has many technologies" do
      category = create(:category, :with_technology)

      expect(category.technologies.count).to eq(1)
    end
  end

  describe "default scope" do
    it "orders categories by name" do
      z_category = create(:category, name: "Zeta")
      a_category = create(:category, name: "Alpha")

      expect(described_class.ordered).to eq([a_category, z_category])
    end
  end

  describe "#destroy" do
    it "prevents destruction when technologies exist" do
      category = create(:category, :with_technology)

      category.destroy
      expect(category.errors[:base]).to include(I18n.t("activerecord.errors.messages.restrict_dependent_destroy.has_many", record: "technologies"))
    end

    it "allows destruction when no technologies exist" do
      category = create(:category)

      expect { category.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
