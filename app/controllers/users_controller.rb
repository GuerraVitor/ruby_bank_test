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

  # --- Statement Action ---
  def statement
    @user = current_user
    @transactions = @user.transactions.order(created_at: :desc)
  end

    # --- Transfer Actions ---

  def transfer_form
    @user = current_user
  end

  def process_transfer
    @user = current_user
    recipient_username = params[:recipient_username]
    amount_in_reais = params[:amount].to_f
    amount_in_cents = (amount_in_reais * 100).round # Convert to cents

    # Basic validations
    if amount_in_cents <= 0
      flash[:alert] = "Transfer amount must be positive."
      redirect_to transfer_form_path
      return
    end

    if recipient_username.blank?
      flash[:alert] = "Recipient username cannot be empty."
      redirect_to transfer_form_path
      return
    end

    recipient = User.find_by(username: recipient_username)

    if recipient.nil?
      flash[:alert] = "Recipient account does not exist."
      redirect_to transfer_form_path
      return
    end

    if recipient == @user
      flash[:alert] = "Cannot transfer to your own account."
      redirect_to transfer_form_path
      return
    end

    # Calculate fee and total debit (transfer amount + fee)
    transfer_fee_cents = 0
    total_debit_cents = amount_in_cents

    if @user.vip?
      # VIP user: 0.8% of transferred amount
      transfer_fee_cents = (amount_in_cents * 0.008).round.to_i
      total_debit_cents = amount_in_cents + transfer_fee_cents
    else # Normal User
      # Normal user: R$8.00 fixed fee
      transfer_fee_cents = 800 # 800 cents = R$8.00
      total_debit_cents = amount_in_cents + transfer_fee_cents

      # Normal User Transfer Limit
      if amount_in_cents > 100000 # R$1,000.00
        flash[:alert] = "Normal users cannot transfer more than R$1,000.00."
        redirect_to transfer_form_path
        return
      end
    end

    # Check if sender has sufficient balance for the transfer + fee
    if @user.balance < total_debit_cents
      flash[:alert] = "Insufficient balance to cover transfer and fees."
      redirect_to transfer_form_path
      return
    end

    # --- Process the Transfer within a Transaction ---
    ActiveRecord::Base.transaction do
      # 1. Debit sender's account
      @user.balance -= total_debit_cents

      # If VIP user goes from positive to negative due to transfer, record the time
      if @user.vip? && @user.balance >= 0 && (@user.balance - total_debit_cents < 0)
        @user.last_negative_balance_at = Time.current
      end

      # 2. Credit recipient's account
      recipient.balance += amount_in_cents

      # 3. Save both users
      unless @user.save && recipient.save
        raise ActiveRecord::Rollback, "Failed to save sender or recipient account."
      end

      # 4. Create sender's transaction record
      Transaction.create!(
        user: @user,
        transaction_type: 'transfer_out',
        amount: amount_in_cents, # Amount transferred, not including fee
        description: "Transfer to account #{recipient.username}",
        recipient_account_id: recipient.id,
        sender_account_id: @user.id
      )

      # 5. Create recipient's transaction record
      Transaction.create!(
        user: recipient,
        transaction_type: 'transfer_in',
        amount: amount_in_cents,
        description: "Transfer from account #{@user.username}",
        recipient_account_id: recipient.id,
        sender_account_id: @user.id
      )

      # 6. Create sender's fee transaction record (if applicable)
      if transfer_fee_cents > 0
        Transaction.create!(
          user: @user,
          transaction_type: 'transfer_fee',
          amount: transfer_fee_cents,
          description: "Transfer fee",
          sender_account_id: @user.id # Fee is associated with sender
        )
      end

      flash[:notice] = "Successfully transferred #{'R$ %.2f' % amount_in_reais} to account #{recipient.username}."
      redirect_to dashboard_path
    rescue ActiveRecord::Rollback => e
      flash[:alert] = "Transfer failed: #{e.message}"
      redirect_to transfer_form_path
    rescue => e # Catch any other unexpected errors during transaction
      flash[:alert] = "An unexpected error occurred during transfer: #{e.message}"
      redirect_to transfer_form_path
    end
  end

   # --- Manager Visit Actions (VIP only) ---

  def manager_visit_confirm
    @user = current_user
    # Nothing else needed here, just renders the confirmation view
  end

  def request_manager_visit
    @user = current_user
    manager_visit_fee_cents = 5000 # R$50.00

    if @user.balance < manager_visit_fee_cents
      flash[:alert] = "Insufficient balance to request manager visit (R$50.00 fee)."
      redirect_to dashboard_path
      return
    end

    ActiveRecord::Base.transaction do
      @user.balance -= manager_visit_fee_cents
      @user.last_negative_balance_at = Time.current if @user.vip? && @user.balance < 0 # Update timestamp if VIP goes negative

      if @user.save
        Transaction.create!(
          user: @user,
          transaction_type: 'manager_visit_fee',
          amount: manager_visit_fee_cents,
          description: "Manager visit request fee"
        )
        flash[:notice] = "Manager visit requested! R$50.00 debited from your account. A manager will contact you soon."
        redirect_to dashboard_path
      else
        flash[:alert] = "Failed to process manager visit request."
        raise ActiveRecord::Rollback
      end
    rescue ActiveRecord::Rollback
      redirect_to manager_visit_confirm_path # Redirect back to confirmation if rollback occurs
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