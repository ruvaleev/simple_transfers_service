require "rails_helper"

RSpec.describe Orders::Cancel do
  subject(:call_service) { described_class.call(order:) }

  let(:source_account) { create(:account, balance: 500) }
  let(:destination_account) { create(:account, balance: 200) }
  let(:order) { create(:order, source_account:, destination_account:, amount:, status:) }
  let(:amount) { 150 }
  let(:status) { :created }

  context 'when order is in :created status' do
    it { is_expected.to be_success }

    it 'cancels order' do
      expect { call_service }.to change(order, :status).from('created').to('cancelled')
    end

    it "doesn't created new LedgerEntry records" do
      expect { call_service }.not_to change(LedgerEntry, :count)
    end

    it "doesn't change source account balance" do
      expect { call_service }.not_to change { source_account.reload.balance }
    end

    it "doesn't change destination account balance" do
      expect { call_service }.not_to change { destination_account.reload.balance }
    end
  end

  context 'when order is in :successful status already' do
    let(:status) { :successful }

    it { is_expected.to be_success }

    it 'cancels order' do
      expect { call_service }.to change(order, :status).from('successful').to('cancelled')
    end

    it 'increases source account balance properly' do
      expect { call_service }.to change { source_account.reload.balance }.from(500).to(650)
    end

    it 'reduces destination account balance properly' do
      expect { call_service }.to change { destination_account.reload.balance }.from(200).to(50)
    end

    it 'creates two ledger_entires with proper attributes' do # rubocop:disable RSpec/MultipleExpectations
      expect { call_service }.to change(LedgerEntry, :count).by(2)

      expect(order.ledger_entries.credits.first).to have_attributes(
        account: source_account, entry_type: 'reversal', amount:
      )
      expect(order.ledger_entries.debits.first).to have_attributes(
        account: destination_account, entry_type: 'reversal', amount:
      )
    end
  end

  context 'when order is in :cancelled status' do
    let(:status) { :cancelled }

    it { is_expected.to be_success }

    it "doesn't change order status" do
      expect { call_service }.not_to change(order, :status)
    end

    it "doesn't created new LedgerEntry records" do
      expect { call_service }.not_to change(LedgerEntry, :count)
    end

    it "doesn't change source account balance" do
      expect { call_service }.not_to change { source_account.reload.balance }
    end

    it "doesn't change destination account balance" do
      expect { call_service }.not_to change { destination_account.reload.balance }
    end
  end

  context "with two concurrent requests in parallel" do
    let(:order) { create(:order, status: :successful, source_account:, destination_account:, amount: 50) }

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
      expect(order).to be_cancelled
      expect(order.ledger_entries.count).to eq(2)
      expect(source_account.reload.balance).to eq(550)
      expect(destination_account.reload.balance).to eq(150)
    end
  end
end
