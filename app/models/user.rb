class User < ApplicationRecord
  has_many :transactions, dependent: :destroy

  validates :username, presence: true, uniqueness: true, format: { with: /\A\d{5}\z/, message: "5 dígitos" }
  validates :password, presence: true, format: { with: /\A\d{4}\z/, message: "numérica com 4 dígitos" }
  validates :balance, numericality: { only_integer: true }

  def vip?
    vip
  end

    def formatted_balance
    "R$ %.2f" % (balance / 100.0)
  end

  def balance_in_reais
    balance / 100.0
  end

  def balance_in_reais=(value)
    self.balance = (value.to_f * 100).round
  end

end