module Orders
  Result = Struct.new(:success, :order, :error, keyword_init: true) do
    alias_method :success?, :success

    def self.success(order)
      new(success: true, order: order, error: nil)
    end

    def self.failure(order, error)
      new(success: false, order: order, error: error)
    end
  end
end
