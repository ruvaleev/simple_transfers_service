require 'rails_helper'

RSpec.describe Order do
  subject(:order) { build(:order) }

  it { is_expected.to belong_to(:destination_account).class_name(:Account) }
  it { is_expected.to belong_to(:initiator) }
  it { is_expected.to belong_to(:source_account).class_name(:Account) }

  it { is_expected.to have_many(:ledger_entries).dependent(:restrict_with_exception) }

  it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
  it { is_expected.to validate_presence_of(:idempotency_key) }
  it { is_expected.to validate_uniqueness_of(:idempotency_key) }

  describe "validations" do
    let(:user) { create(:user) }
    let(:source_account) { create(:account, user:) }

    context 'with :destination_account' do
      subject(:order) { build(:order, initiator: user, source_account:, destination_account:) }

      context 'when :destination_account matches :source_account' do
        let(:destination_account) { source_account }

        it { is_expected.not_to be_valid }
      end

      context "when :destination_account doesn't match :source_account" do
        let(:destination_account) { create(:account) }

        it { is_expected.to be_valid }
      end
    end

    context 'with :source_account' do
      subject(:order) { build(:order, initiator:, source_account:) }

      context 'when :initiator is the user of source account' do
        let(:initiator) { user }

        it { is_expected.to be_valid }
      end

      context 'when :initiator is not the user of source account' do
        let(:initiator) { create(:user) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe '.by_user_id' do
    subject(:by_user_id) { described_class.by_user_id(user.id) }

    let(:user) { create(:user) }
    let(:account) { create(:account, user:) }
    let!(:outgoing_order) { create(:order, source_account_id: account.id, initiator: user) }
    let!(:incoming_order) { create(:order, destination_account_id: account.id) }
    let!(:another_order) { create(:order) }

    it { is_expected.to include(outgoing_order, incoming_order) }
    it { is_expected.not_to include(another_order) }
  end

  describe '#internal?' do
    subject(:internal?) { order.internal? }

    let(:order) { build(:order, destination_account_id:, source_account_id:) }
    let(:source_account_id) { rand(1_000) }

    context 'when :destination_account_id is not equal to :source_account_id' do
      let(:destination_account_id) { source_account_id + 1 }

      it { is_expected.to be_falsy }
    end

    context 'when :destination_account_id is equal to :source_account_id' do
      let(:destination_account_id) { source_account_id }

      it { is_expected.to be_truthy }
    end
  end
end
