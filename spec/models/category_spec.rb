require "rails_helper"

RSpec.describe Category, type: :model do
  let_it_be(:existing_category) { create(:category, name: "Backend") }

  describe "validations" do
    it "requires name" do
      category = described_class.new(name: nil)
      category.valid?

      expect(category.errors[:name]).to include("can't be blank")
    end

    it "requires unique name" do
      category = described_class.new(name: existing_category.name)
      category.valid?

      expect(category.errors[:name]).to include("has already been taken")
    end

    it "requires case-insensitive unique name" do
      category = described_class.new(name: existing_category.name.downcase)
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

      expect(described_class.where(id: [a_category.id, z_category.id]).ordered).to eq([a_category, z_category])
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
