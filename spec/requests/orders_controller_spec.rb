require 'rails_helper'

RSpec.describe OrdersController do
  let!(:alice) { create(:user, name: 'Alice') }
  let!(:bob)   { create(:user, name: 'Bob') }
  let!(:alice_main) { create(:account, user: alice, name: 'Main Alice', balance: 1000) }
  let!(:bob_main)   { create(:account, user: bob,   name: 'Main Bob', balance: 500) }

  before { post switch_session_path, params: { user_id: alice.id } }

  describe 'GET /orders' do
    subject(:send_request) { get orders_path }

    let!(:incoming_alice_order) { create(:order, destination_account: alice_main) }
    let!(:outgoing_alice_order) { create(:order, source_account: alice_main) }
    let!(:incoming_bob_order) { create(:order, destination_account: bob_main) }
    let!(:outgoing_bob_order) { create(:order, source_account: bob_main) }

    it 'renders successfull response' do # rubocop:disable RSpec/MultipleExpectations
      send_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Main Alice")
      expect(response.body).not_to include("Main Bob")

      expect(response.body).to include("##{incoming_alice_order.id}")
      expect(response.body).to include("##{outgoing_alice_order.id}")

      expect(response.body).not_to include("##{incoming_bob_order.id}")
      expect(response.body).not_to include("##{outgoing_bob_order.id}")
    end
  end

  describe 'GET /orders/new' do
    subject(:send_request) { get new_order_path }

    let(:alice_secondary) { create(:account, user: alice, name: 'Secondary Alice', balance: 0) }
    let(:bob_secondary) { create(:account, user: bob, name: 'Secondary Bob', balance: 0) }

    it 'embeds an idempotency_key hidden field' do # rubocop:disable RSpec/MultipleExpectations
      send_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="order[idempotency_key]"')
      expect(response.body).to match(/id="order_idempotency_key"/)
      expect(response.body).to match(/value="[a-f0-9-]{36}"/)
    end

    it "includes only current user's accounts as source options" do # rubocop:disable RSpec/MultipleExpectations
      alice_secondary
      bob_secondary

      send_request

      source_select = response.body[/<select[^>]*name="order\[source_account_id\]".*?<\/select>/m]
      expect(source_select).to include(%(value="#{alice_main.id}"), %(value="#{alice_secondary.id}"))
      expect(source_select).not_to include(%(value="#{bob_main.id}"), %(value="#{bob_secondary.id}"))
    end
  end

  describe 'POST /orders' do
    subject(:send_request) { post orders_path, params: params }

    let(:params) { { order: order_params } }
    let(:order_params) do
      {
        source_account_id:,
        destination_account_id: bob_main.id,
        amount:,
        idempotency_key:
      }
    end
    let(:source_account_id) { alice_main.id }
    let(:amount) { '150.50' }
    let(:idempotency_key) { SecureRandom.uuid }

    it 'creates an order with proper params' do # rubocop:disable RSpec/MultipleExpectations
      expect { send_request }.to change(alice_main.outgoing_orders, :count).by(1)
      order = Order.last
      expect(order).to have_attributes(
        order_params
          .slice(:source_account_id, :destination_account_id, :idempotency_key)
          .merge(amount: BigDecimal(amount))
      )
    end

    it 'is idempotent on duplicate submit' do
      send_request
      expect { post orders_path, params: params }.not_to change(Order, :count)
    end

    context "when :source_account_id doesn't belong to current_user" do
      let(:source_account) { create(:account) }
      let(:source_account_id) { source_account.id }

      it 'returns :not_found error' do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid parameters' do
      let(:amount) { 0 }

      it "doesn't create new order" do
        expect { send_request }.not_to change(Order, :count)
      end

      it 'returns proper error info' do # rubocop:disable RSpec/MultipleExpectations
        send_request
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Amount must be greater than 0')
      end
    end
  end

  describe 'GET /orders/:id' do
    subject(:send_request) { get order_path(order) }

    context 'when current user owns the source account' do
      let(:order) do
        create(:order, source_account: alice_main, destination_account: bob_main, amount: 200, initiator: alice)
      end

      it 'renders the order card' do # rubocop:disable RSpec/MultipleExpectations
        send_request

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Main Alice', 'Main Bob', '200.00')
      end

      context 'when the order has no ledger entries yet' do
        it 'shows the empty-ledger placeholder' do
          send_request

          expect(response.body).to include('No ledger entries yet')
        end
      end

      context 'when the order has some ledger entries already' do
        let!(:debit_entry) { create(:ledger_entry, order:, direction: :debit) } # rubocop:disable RSpec/LetSetup
        let!(:credit_entry) { create(:ledger_entry, order:, direction: :credit) } # rubocop:disable RSpec/LetSetup

        it 'lists both normal entries' do
          send_request

          expect(response.body).to include('normal', 'debit', 'credit')
        end
      end
    end

    context 'when current user owns the destination account' do
      let(:order) { create(:order, destination_account: alice_main, amount: 200) }

      it 'renders the order card' do # rubocop:disable RSpec/MultipleExpectations
        send_request

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Main Alice', '200.00')
      end
    end

    context 'when the order belongs to neither account of the current user' do
      let(:order) { create(:order) }

      it 'returns 404' do
        send_request

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /orders/:id/confirm' do
    subject(:send_request) { post confirm_order_path(order) }

    let(:order) do
      create(:order, source_account: alice_main, destination_account: bob_main, amount: 200, initiator: alice)
    end

    it "confirms the order and updates balances" do # rubocop:disable RSpec/MultipleExpectations
      expect { send_request }.to change { order.reload.status }.from('created').to('successful')

      expect(alice_main.reload.balance).to eq(800)
      expect(bob_main.reload.balance).to eq(700)
    end
  end

  describe "POST /orders/:id/cancel" do
    subject(:send_request) { post cancel_order_path(order) }

    let(:order) do
      create(:order,
        source_account: alice_main,
        destination_account: bob_main,
        amount: 200,
        initiator: alice,
        status:
      )
    end

    context 'when order is in :created status' do
      let(:status) { :created }

      it "cancels a created order and doesn't create new ledger entries" do # rubocop:disable RSpec/MultipleExpectations
        expect { send_request }.not_to change(order.ledger_entries, :count)

        expect(order.reload.status).to eq('cancelled')
        expect(alice_main.reload.balance).to eq(1000)
        expect(bob_main.reload.balance).to eq(500)
      end
    end

    context 'when order is already in :successful status' do
      let(:status) { :successful }

      it "creates reverse ledger entry with proper amounts" do # rubocop:disable RSpec/MultipleExpectations
        expect { send_request }.to change(order.ledger_entries, :count).by(2)

        alice_reversal_entry = order.ledger_entries.reversals.find_by(account: alice_main)
        bob_reversal_entry = order.ledger_entries.reversals.find_by(account: bob_main)

        expect(alice_reversal_entry.amount).to eq(order.amount)
        expect(bob_reversal_entry.amount).to eq(order.amount)

        expect(alice_main.reload.balance).to eq(1200)
        expect(bob_main.reload.balance).to eq(300)
      end
    end
  end
end
