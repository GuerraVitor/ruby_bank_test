class UsersController < ApplicationController
 
  before_action :require_login

  def dashboard
    @user = current_user 

    if @user.vip? && @user.balance < 0 && @user.last_negative_balance_at.present?
      calculate_and_apply_vip_negative_balance_fee(@user)
    end

  end

    # --- Deposit Actions ---

  def deposit_form
    @user = current_user
  end

  def process_deposit
    @user = current_user
    amount_in_reais = params[:amount].to_f
    amount_in_cents = (amount_in_reais * 100).round

    if amount_in_cents <= 0
      flash[:alert] = "A quantia do depósito precisa ser positiva."
      redirect_to deposit_form_path
      return
    end

    ActiveRecord::Base.transaction do
      @user.balance += amount_in_cents
      @user.last_negative_balance_at = nil if @user.balance >= 0 # Clear timestamp if balance becomes positive

      if @user.save
        Transaction.create!(
          user: @user,
          transaction_type: 'deposit',
          amount: amount_in_cents,
          description: "Depósito"
        )
        flash[:notice] = "Depósito realizado no valor de #{'R$ %.2f' % amount_in_reais}."
        redirect_to dashboard_path
      else
        flash[:alert] = "Falha ao realizar o depósito."
        raise ActiveRecord::Rollback # Rollback transaction if save fails
      end
    rescue ActiveRecord::Rollback
      redirect_to deposit_form_path
    end
  end

  # --- Withdrawal Actions ---

  def withdraw_form
    @user = current_user
  end

  def process_withdraw
    @user = current_user
    amount_in_reais = params[:amount].to_f
    amount_in_cents = (amount_in_reais * 100).round

    if amount_in_cents <= 0
      flash[:alert] = "o valor do saque precisa ser positivo."
      redirect_to withdraw_form_path
      return
    end

    # Normal User Withdrawal Rule
    if !@user.vip? && amount_in_cents > @user.balance
      flash[:alert] = "você não possui fundos suficientes."
      redirect_to withdraw_form_path
      return
    end

    # VIP User Withdrawal Rule
    if @user.vip? && @user.balance >= 0 && (@user.balance - amount_in_cents < 0)
      # If VIP goes from positive to negative, record the time
      @user.last_negative_balance_at = Time.current
    end

    ActiveRecord::Base.transaction do
      @user.balance -= amount_in_cents

      if @user.save
        Transaction.create!(
          user: @user,
          transaction_type: 'withdrawal',
          amount: amount_in_cents,
          description: "Saque"
        )
        flash[:notice] = "Saque realizado com sucesso! #{'R$ %.2f' % amount_in_reais}."
        redirect_to dashboard_path
      else
        flash[:alert] = "Saque não realizado."
        raise ActiveRecord::Rollback
      end
    rescue ActiveRecord::Rollback
      redirect_to withdraw_form_path
    end
  end

  private

  def calculate_and_apply_vip_negative_balance_fee(user)
    time_since_last_check = Time.current - user.last_negative_balance_at
    minutes_negative = (time_since_last_check / 60).floor

    if minutes_negative > 0
      fee_per_minute_value = (user.balance.abs * 0.001)
      total_fee_cents = (fee_per_minute_value * minutes_negative).round.to_i

      total_fee_cents = [total_fee_cents, user.balance.abs].min

      if total_fee_cents > 0
        user.balance -= total_fee_cents
        user.save

        # Record the transaction
        Transaction.create!(
          user: user,
          transaction_type: 'negative_balance_fee',
          amount: total_fee_cents,
          description: "taxa de balanço negativo (VIP) para #{minutes_negative} minutos"
        )
      end
    end
    # Always update the timestamp to reflect when the check happened
    user.update(last_negative_balance_at: Time.current)
  end

end