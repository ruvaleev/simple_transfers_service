module Orders
  class Confirm
    attr_reader :order

    def self.call(order:)
      new(order: order).call
    end

    def initialize(order:)
      @order = order
    end

    def call
      ActiveRecord::Base.transaction do
        order.lock!
        return Result.success(order) if order.successful?
        return Result.failure(order, :invalid_transition) unless order.created?

        accounts = [ order.source_account, order.destination_account ].sort_by(&:id) # to prevent deadlock
        accounts.each(&:lock!)

        if order.source_account.balance < order.amount
          return Result.failure(order, :insufficient_balance)
        end

        create_entries!
        update_balances!
        order.successful!

        Result.success(order)
      end
    end

    private

    def create_entries!
      ledger_entires = order.ledger_entries.normals
      ledger_entires.debit.create!(account: order.source_account, amount: order.amount)
      ledger_entires.credit.create!(account: order.destination_account, amount: order.amount)
    end

    def update_balances!
      order.source_account.update!(balance: order.source_account.balance - order.amount)
      order.destination_account.update!(balance: order.destination_account.balance + order.amount)
    end
  end
end
