module Orders
  class Cancel
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
        return Result.success(order) if order.cancelled?

        case order.status.to_sym
        when :created
          order.cancelled!
        when :successful
          reverse_transfer!
        else
          return Result.failure(order, :invalid_transition)
        end

        Result.success(order)
      end
    end

    private

    def reverse_transfer!
      accounts = [ order.source_account, order.destination_account ].sort_by(&:id)
      accounts.each(&:lock!)

      create_entries!
      update_balances!
      order.cancelled!
    end

    def create_entries!
      ledger_entires = order.ledger_entries.reversals
      ledger_entires.credit.create!(account: order.source_account, amount: order.amount)
      ledger_entires.debit.create!(account: order.destination_account, amount: order.amount)
    end

    def update_balances!
      order.source_account.update!(balance: order.source_account.balance + order.amount)
      order.destination_account.update!(balance: order.destination_account.balance - order.amount)
    end
  end
end
