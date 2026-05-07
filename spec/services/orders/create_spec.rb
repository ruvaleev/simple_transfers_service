require "rails_helper"

RSpec.describe Orders::Create do
  subject(:call_service) { described_class.call(**params) }

  let(:params) { { source_account:, destination_account:, amount:, initiator:, idempotency_key: } }
  let(:source_account) { create(:account, balance: 500) }
  let(:destination_account) { create(:account, balance: 0) }
  let(:amount) { 100 }
  let(:initiator) { source_account.user }
  let(:idempotency_key) { SecureRandom.uuid }

  it { is_expected.to be_success }

  it 'creates order in :created state and with proper params' do # rubocop:disable RSpec/MultipleExpectations
    expect { call_service }.to change(Order, :count).by(1)

    expect(Order.last).to have_attributes(params)
  end

  it 'does not create ledger entries or change balances' do
    expect { call_service }.not_to change(LedgerEntry, :count)
  end

  it 'does not change source_account balance' do
    expect { call_service }.not_to change { source_account.reload.balance }
  end

  it 'does not change destination_account balance' do
    expect { call_service }.not_to change { destination_account.reload.balance }
  end

  context 'when order with same idempotency_key already exists' do
    let!(:existing_order) { create(:order, idempotency_key:) }

    it { is_expected.to be_success }

    it "doesn't create new order" do
      expect { call_service }.not_to change(Order, :count)
    end

    it 'returns existing order' do
      expect(call_service.order).to eq(existing_order)
    end
  end

  context "when amount is invalid" do
    let(:amount) { 0 }

    it { is_expected.not_to be_success }

    it 'returns error key in result' do
      expect(call_service.error).to be(:invalid)
    end

    it 'returns errors info along with the record' do
      expect(call_service.order.errors.messages).to eq({ amount: [ "must be greater than 0" ] })
    end
  end
end
