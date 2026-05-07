require 'rails_helper'

RSpec.describe User do
  subject(:user) { build(:user) }

  it { is_expected.to have_many(:accounts).dependent(:restrict_with_exception) }

  it {
    expect(user).to have_many(:initiated_orders)
      .class_name(:Order).with_foreign_key(:initiator_id).dependent(:restrict_with_exception)
  }

  it { is_expected.to validate_presence_of(:name) }
end
