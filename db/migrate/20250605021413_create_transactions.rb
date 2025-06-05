class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true 
      t.string :transaction_type, null: false
      t.integer :amount, null: false
      t.string :description, null: false
      t.integer :recipient_account_id 
      t.integer :sender_account_id 

      t.timestamps
    end
  end
end