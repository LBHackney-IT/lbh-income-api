require 'rails_helper'

describe Hackney::Income::Jobs::AddActionDiaryEntryJob do
  subject(:action_diary_job) { described_class }

  let(:mock_action_diary_usecase) { double(Hackney::Tenancy::AddActionDiaryEntry) }

  let(:tenancy_ref) { Faker::Internet.slug }
  let(:action_code) { Faker::Lorem.word }
  let(:comment) { Faker::Lorem.paragraph }

  before do
    stub_const('Hackney::Tenancy::AddActionDiaryEntry', mock_action_diary_usecase)
    allow(mock_action_diary_usecase).to receive(:new).and_return(mock_action_diary_usecase)
  end

  it 'calls usecase with correct args' do
    expect(mock_action_diary_usecase).to receive(:execute).with(
      hash_including(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: nil
      )
    ).once
    action_diary_job.perform_now(tenancy_ref: tenancy_ref, action_code: action_code, comment: comment)
  end

  it 'is able to be scheduled' do
    expect do
      action_diary_job.set(wait_until: Time.now + 5.minutes).perform_later
    end.not_to raise_error
  end
end
