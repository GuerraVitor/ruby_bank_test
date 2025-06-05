class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :username, null: false, limit: 5
      t.string :password, null: false, limit: 4
      t.integer :balance, default: 0
      t.boolean :vip, default: false
      t.datetime :last_negative_balance_at

      t.timestamps
    end
    add_index :users, :username, unique: true
  end
end
