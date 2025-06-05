class Transaction < ApplicationRecord
  belongs_to :user

  belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_account_id', optional: true
  
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_account_id', optional: true

  validates :transaction_type, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
end