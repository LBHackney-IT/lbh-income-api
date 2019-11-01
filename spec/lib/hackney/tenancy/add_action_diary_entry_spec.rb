require 'rails_helper'

describe Hackney::Tenancy::AddActionDiaryEntry do
  let(:action_diary_gateway) { double(Hackney::Tenancy::Gateway::ActionDiaryGateway) }
  let(:username) { Faker::Name.name }

  let(:usecase) { described_class.new(action_diary_gateway: action_diary_gateway) }
  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:action_code) { Faker::Internet.slug }
  let(:comment) { Faker::Lorem.paragraph }
  let(:date) { Faker::Date.backward }

  context 'when the system wants to add an action diary message' do
    subject { usecase.execute(tenancy_ref: tenancy_ref, action_code: action_code, comment: comment) }

    it 'calls the action_diary_gateway' do
      allow(DateTime).to receive(:now).and_return(date)

      expect(action_diary_gateway).to receive(:create_entry)
        .with(tenancy_ref: tenancy_ref, action_code: action_code, comment: comment, username: nil, date: date)
        .once

      subject
    end
  end

  it 'optional date can be supplied that is passed to the gateway' do
    given_date = Faker::Date.backward

    expect(action_diary_gateway).to receive(:create_entry)
      .with(tenancy_ref: tenancy_ref, action_code: action_code, comment: comment, username: nil, date: given_date)
      .once

    usecase.execute(tenancy_ref: tenancy_ref, action_code: action_code, comment: comment, date: given_date)
  end

  context 'when a user wants to add an action diary message' do
    subject { usecase.execute(username: username, tenancy_ref: tenancy_ref, action_code: action_code, comment: comment) }

    let(:username) { Faker::Name.name }

    it 'calls the action_diary_gateway' do
      allow(DateTime).to receive(:now).and_return(date)

      expect(action_diary_gateway).to receive(:create_entry)
        .with(tenancy_ref: tenancy_ref, action_code: action_code, comment: comment, username: username, date: date)
        .once

      subject
    end
  end
end
