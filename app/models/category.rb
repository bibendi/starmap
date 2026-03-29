class Category < ApplicationRecord
  has_many :technologies, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: {case_sensitive: false}

  scope :ordered, -> { order(:name) }
end
