require "rails_helper"

RSpec.describe Account do
  it { is_expected.to belong_to(:user) }

  it { is_expected.to have_many(:incoming_orders).class_name(:Order).with_foreign_key(:destination_account_id) }
  it { is_expected.to have_many(:ledger_entries) }
  it { is_expected.to have_many(:outgoing_orders).class_name(:Order).with_foreign_key(:source_account_id) }

  it { is_expected.to validate_numericality_of(:balance).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_presence_of(:name) }

  describe "#calculated_balance" do
    let(:account) { create(:account, balance: 100) }

    it "returns actual sum of credits minus debits" do
      create(:ledger_entry, account:, direction: :credit, amount: 250)
      create(:ledger_entry, account:, direction: :debit, amount: 100)

      expect(account.calculated_balance).to eq(150)
    end

    it "returns 0 when no entries" do
      expect(account.calculated_balance).to eq(0)
    end
  end
end
