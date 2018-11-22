require 'rails_helper'

describe Hackney::Tenancy::AddActionDiaryEntry do
  let(:action_diary_gateway) { double(Hackney::Tenancy::ActionDiaryGateway) }

  let(:usecase) { described_class.new(action_diary_gateway: action_diary_gateway) }

  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:action_balance) { Faker::Commerce.price }
  let(:username) { Faker::Name.name }
  let(:action_code) { Faker::Internet.slug }
  let(:comment) { Faker::Lorem.paragraph }

  subject { usecase.execute(tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment, username: username) }

  it 'should call the action_diary_gateway' do
    expect(action_diary_gateway).to receive(:create_entry)
      .with(tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment, username: username)
      .once

    subject
  end
end
