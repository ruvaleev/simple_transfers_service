class OrdersController < ApplicationController
  before_action :set_current_user
  before_action :set_order, only: [ :confirm, :cancel ]

  helper_method :other_users

  def index
    @accounts = current_user.accounts.order(:name)
    @orders = Order.by_user_id(current_user.id)
                   .includes(source_account: :user, destination_account: :user)
                   .order(created_at: :desc)
  end

  def new
    prepare_form
  end

  def show
    @order = Order.by_user_id(current_user.id).find(params[:id])
    @ledger_entries = @order.ledger_entries.includes(account: :user).order(:created_at)
  end

  def create
    source_account = current_user.accounts.find(params[:order][:source_account_id])
    destination_account = Account.find(params[:order][:destination_account_id])

    result = Orders::Create.call(
      source_account:,
      destination_account:,
      amount: params[:order][:amount],
      initiator: current_user,
      idempotency_key: params[:order][:idempotency_key]
    )

    if result.success?
      redirect_to orders_path, notice: "Order ##{result.order.id} created"
    else
      flash.now[:alert] = error_message(result.error, result.order)
      prepare_form(order: result.order, idempotency_key: params[:order][:idempotency_key].presence)
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    result = Orders::Confirm.call(order: @order)
    redirect_to orders_path, **flash_for(result, "Order ##{@order.id} confirmed")
  end

  def cancel
    result = Orders::Cancel.call(order: @order)
    redirect_to orders_path, **flash_for(result, "Order ##{@order.id} cancelled")
  end

  private

  def set_order
    @order = Order.by_user_id(current_user.id).find(params[:id])
  end

  def prepare_form(order: nil, idempotency_key: nil)
    @order = order || Order.new
    @source_accounts = current_user.accounts.order(:name)
    @destination_accounts = Account.where.not(user: current_user).includes(:user).order(:name)
    @idempotency_key = idempotency_key || SecureRandom.uuid
  end

  def flash_for(result, success_msg)
    if result.success?
      { notice: success_msg }
    else
      { alert: error_message(result.error, result.order) }
    end
  end

  def error_message(error, order)
    case error
    when :insufficient_balance then 'Insufficient balance on source account'
    when :invalid_transition   then "Cannot transition order from #{order&.status}"
    when :invalid              then order&.errors&.full_messages&.to_sentence.presence || 'Invalid order'
    when :idempotency_collision then 'Idempotency key collision'
    else "Operation failed: #{error}"
    end
  end

  def other_users
    User.where.not(id: current_user.id).order(:name)
  end
end
