require 'rails_helper'

describe Hackney::Income::CreateEvictionAndSync do
  subject {
    described_class.new(
      add_action_diary_and_sync_case: add_action_diary_and_sync_case_usecase,
      create_eviction: create_eviction_usecase
    )
  }

  let(:add_action_diary_and_sync_case_usecase) { double(UseCases::AddActionDiaryAndSyncCase) }
  let(:create_eviction_usecase) { double(Hackney::Income::CreateEviction) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:date) { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
  let(:username) { Faker::TvShows::StrangerThings.character }

  let(:new_eviction_params) do
    {
      tenancy_ref: tenancy_ref,
      date: date
    }
  end

  context 'when a username is provided' do
    it 'calls create date usecase and adds an action diary and sync' do
      expect(add_action_diary_and_sync_case_usecase).to receive(:execute).with(
        tenancy_ref: tenancy_ref,
        action_code: 'EDS',
        comment: "Eviction date set to #{date}",
        username: username
      )

      expect(create_eviction_usecase).to receive(:execute).with(
        eviction_params: new_eviction_params
      )

      subject.execute(eviction_params: new_eviction_params, username: username)
    end
  end

  it 'creates and returns a new eviction date' do
    expect(add_action_diary_and_sync_case_usecase).not_to receive(:execute).with(
      tenancy_ref: tenancy_ref,
      action_code: 'EDS',
      comment: "Eviction date set to #{date}",
      username: username
    )

    expect(create_eviction_usecase).to receive(:execute).with(
      eviction_params: new_eviction_params
    )

    subject.execute(eviction_params: new_eviction_params)
  end
end
