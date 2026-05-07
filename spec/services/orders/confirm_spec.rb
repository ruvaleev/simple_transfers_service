require "rails_helper"

RSpec.describe Orders::Confirm do
  subject(:call_service) { described_class.call(order:) }

  let(:source_account) { create(:account, balance: 500) }
  let(:destination_account) { create(:account, balance: 100) }
  let(:order) { create(:order, source_account:, destination_account:, amount:) }
  let(:amount) { 200 }

  it { is_expected.to be_success }

  it 'updates order status to :successful' do
    expect { call_service }.to change(order, :status).from('created').to('successful')
  end

  it 'reduces source account balance properly' do
    expect { call_service }.to change { source_account.reload.balance }.from(500).to(300)
  end

  it 'increases destination account balance properly' do
    expect { call_service }.to change { destination_account.reload.balance }.from(100).to(300)
  end

  it 'creates two ledger_entires with proper attributes' do # rubocop:disable RSpec/MultipleExpectations
    expect { call_service }.to change(LedgerEntry, :count).by(2)

    expect(order.ledger_entries.credits.first).to have_attributes(
      account: destination_account, entry_type: 'normal', amount:
    )
    expect(order.ledger_entries.debits.first).to have_attributes(
      account: source_account, entry_type: 'normal', amount:
    )
  end

  shared_examples "doesn't change order, accounts and doesn't create ledger_entries" do
    it "doesn't change order status" do
      expect { call_service }.not_to change(order, :status)
    end

    it "doesn't create ledger entries" do
      expect { call_service }.not_to change(LedgerEntry, :count)
    end

    it "doesn't change source account balance" do
      expect { call_service }.not_to change { source_account.reload.balance }
    end

    it "doesn't change destination account balance" do
      expect { call_service }.not_to change { destination_account.reload.balance }
    end
  end

  context 'when insufficient balance' do
    let(:order) { create(:order, source_account:, destination_account:, amount: 501) }

    it { is_expected.not_to be_success }

    it 'returns error with proper key' do
      expect(call_service.error).to be(:insufficient_balance)
    end

    it_behaves_like "doesn't change order, accounts and doesn't create ledger_entries"
  end

  context 'when order is already in :successful status' do
    let(:order) { create(:order, status: :successful, source_account:, destination_account:, amount:) }

    it { is_expected.to be_success }

    it_behaves_like "doesn't change order, accounts and doesn't create ledger_entries"
  end

  context 'when order is already in :cancelled status' do
    let(:order) { create(:order, status: :cancelled, source_account:, destination_account:, amount:) }

    it { is_expected.not_to be_success }

    it 'returns error with proper key' do
      expect(call_service.error).to be(:invalid_transition)
    end

    it_behaves_like "doesn't change order, accounts and doesn't create ledger_entries"
  end

  context "with two concurrent requests in parallel" do
    let(:order) { create(:order, source_account:, destination_account:, amount: 50) }

    it "returns successful results and consistently updates balances only once" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      results = []
      threads = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            results << described_class.call(order:)
          end
        end
      end
      threads.each(&:join)

      expect(results.count(&:success?)).to eq(2) # both calls are successful
      expect(order).to be_successful
      expect(order.ledger_entries.count).to eq(2)
      expect(source_account.reload.balance).to eq(450)
      expect(destination_account.reload.balance).to eq(150)
    end
  end
end
