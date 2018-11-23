require 'rails_helper'

describe Hackney::Tenancy::AddActionDiaryEntry do
  let(:action_diary_gateway) { double(Hackney::Tenancy::ActionDiaryGateway) }
  let(:users_gateway) { double(Hackney::Income::SqlUsersGateway) }

  let(:usecase) { described_class.new(action_diary_gateway: action_diary_gateway, users_gateway: users_gateway) }

  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:action_balance) { Faker::Commerce.price }
  let(:action_code) { Faker::Internet.slug }
  let(:comment) { Faker::Lorem.paragraph }

  context 'when the system wants to add an action diary message' do
    subject { usecase.execute(tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment) }

    it 'should call the action_diary_gateway' do
      expect(action_diary_gateway).to receive(:create_entry)
        .with(tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment, username: nil)
        .once

      subject
    end
  end

  context 'when a user wants to add an action diary message' do
    let(:user) { OpenStruct.new(name: Faker::Name.name, id: Faker::Number.number(3).to_i) }

    subject { usecase.execute(user_id: user.id, tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment) }

    it 'should call the action_diary_gateway' do
      expect(users_gateway).to receive(:find_user).with(id: user.id).and_return(user).once

      expect(action_diary_gateway).to receive(:create_entry)
        .with(tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment, username: user.name)
        .once

      subject
    end
  end

  context 'when using a non existing user id' do
    let(:user_id) { SecureRandom.uuid }

    subject { usecase.execute(user_id: user_id, tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment) }

    it 'should thow an invalid argument exption' do
      expect(users_gateway).to receive(:find_user).with(id: user_id).and_return(nil).once

      expect { subject }.to raise_error(ArgumentError, 'user_id supplyed does not exist')
    end
  end
end
