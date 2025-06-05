class User < ApplicationRecord
  has_many :transactions, dependent: :destroy

  validates :username, presence: true, uniqueness: true, format: { with: /\A\d{5}\z/, message: "must be 5 digits" }
  validates :password, presence: true, format: { with: /\A\d{4}\z/, message: "must be 4 numeric digits" }
  validates :balance, numericality: { greater_than_or_equal_to: -Float::INFINITY }

  def vip?
    vip
  end
end