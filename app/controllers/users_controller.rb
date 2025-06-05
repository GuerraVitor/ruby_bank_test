class UsersController < ApplicationController
 
  before_action :require_login

  def dashboard
    @user = current_user 

    if @user.vip? && @user.balance < 0 && @user.last_negative_balance_at.present?
      calculate_and_apply_vip_negative_balance_fee(@user)
    end

  end

  private


  def calculate_and_apply_vip_negative_balance_fee(user)
    time_since_last_check = Time.current - user.last_negative_balance_at
    minutes_negative = (time_since_last_check / 60).floor

    if minutes_negative > 0
      
      fee_per_minute = (user.balance.abs * 0.001).round 
      total_fee = fee_per_minute * minutes_negative
      total_fee = [total_fee, user.balance.abs].min

      if total_fee > 0
        user.balance -= total_fee.to_i
        user.save

        Transaction.create(
          user: user,
          transaction_type: 'negative_balance_fee',
          amount: total_fee.to_i,
          description: "Negative balance fee (VIP) for #{minutes_negative} minutes"
        )

      end

    end

    user.update(last_negative_balance_at: Time.current) 

  end
end