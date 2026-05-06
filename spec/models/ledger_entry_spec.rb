require "rails_helper"

RSpec.describe LedgerEntry do
  subject(:ledger_entry) { build(:ledger_entry) }

  it { is_expected.to belong_to(:account) }
  it { is_expected.to belong_to(:order) }

  it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
  it { is_expected.to validate_uniqueness_of(:order_id).scoped_to(:direction, :entry_type) }

  describe '.credits' do
    subject(:credits) { described_class.credits }

    let!(:debit_entry) { create(:ledger_entry, direction: :debit) }
    let!(:credit_entry) { create(:ledger_entry, direction: :credit) }

    it { is_expected.to include(credit_entry) }
    it { is_expected.not_to include(debit_entry) }
  end

  describe '.debits' do
    subject(:debits) { described_class.debits }

    let!(:debit_entry) { create(:ledger_entry, direction: :debit) }
    let!(:credit_entry) { create(:ledger_entry, direction: :credit) }

    it { is_expected.to include(debit_entry) }
    it { is_expected.not_to include(credit_entry) }
  end

  describe '.normals' do
    subject(:normals) { described_class.normals }

    let!(:normal_entry) { create(:ledger_entry, entry_type: :normal) }
    let!(:reversal_entry) { create(:ledger_entry, entry_type: :reversal) }

    it { is_expected.to include(normal_entry) }
    it { is_expected.not_to include(reversal_entry) }
  end

  describe '.reversals' do
    subject(:reversals) { described_class.reversals }

    let!(:normal_entry) { create(:ledger_entry, entry_type: :normal) }
    let!(:reversal_entry) { create(:ledger_entry, entry_type: :reversal) }

    it { is_expected.to include(reversal_entry) }
    it { is_expected.not_to include(normal_entry) }
  end

  describe "immutability" do
    subject(:ledger_entry) { create(:ledger_entry) }

    it { is_expected.to be_readonly }

    it "raises on update attempts" do
      expect { ledger_entry.update!(amount: 200) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
