require 'rails_helper'

describe UseCases::AddActionDiaryAndSyncCase do
  let(:add_action_diary_and_sync_case) {
    described_class.new(sync_case_priority: sync_case_priority,
                        add_action_diary: add_action_diary)
  }

  let(:sync_case_priority) { spy }
  let(:add_action_diary) { spy }

  let(:username) { Faker::Name.name }
  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:action_code) { Faker::Internet.slug }
  let(:comment) { Faker::Lorem.paragraph }

  context 'when adding to the action diary and syncing a case' do
    it 'will call the add_action_diary and sync_case_priority usecase with the correct data' do
      add_action_diary_and_sync_case.execute(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username
      )
      allow(add_action_diary_and_sync_case).to receive(:execute)
      expect(sync_case_priority).to have_received(:execute)
      expect(add_action_diary).to have_received(:execute)
    end
  end
end
