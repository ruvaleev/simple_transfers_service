module Orders
  class Create
    attr_reader :source_account, :destination_account, :amount, :initiator, :idempotency_key, :kind

    def self.call(**args)
      new(**args).call
    end

    def initialize(source_account:, destination_account:, amount:, initiator:, idempotency_key:, kind: :transfer)
      @source_account = source_account
      @destination_account = destination_account
      @amount = amount
      @initiator = initiator
      @idempotency_key = idempotency_key
      @kind = kind
    end

    def call
      order = Order.find_or_initialize_by(idempotency_key:)
      return Result.success(order) if order.persisted?

      save_order(order)
      Result.success(order)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record, :invalid)
    end

    private

    def save_order(order)
      order.update!(
        source_account:,
        destination_account:,
        initiator:,
        amount:,
        kind:,
        status: :created
      )
    end
  end
end
