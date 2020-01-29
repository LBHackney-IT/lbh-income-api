require 'rails_helper'

describe UseCases::AddActionDiaryAndPauseCase do
  let(:add_action_diary_and_sync_case) {
    described_class.new(sql_pause_tenancy_gateway: sql_pause_tenancy_gateway,
                        add_action_diary: add_action_diary)
  }

  let(:sql_pause_tenancy_gateway) { spy }
  let(:add_action_diary) { spy }

  let(:username) { Faker::Name.name }
  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:action_code) { Faker::Internet.slug }
  let(:comment) { Faker::Lorem.paragraph }

  context "when adding to the action diary that doesn't need to be paused for rsync" do
    it "will call the add_action_diary with the correct data and doesn't call sql_pause_tenancy_gateway" do
      add_action_diary_and_sync_case.execute(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username
      )

      allow(add_action_diary_and_sync_case).to receive(:execute)
      expect(sql_pause_tenancy_gateway).not_to have_received(:set_paused_until)
      expect(add_action_diary).to have_received(:execute)
    end
  end

  context 'when adding to the action diary that needs to be paused for rsync' do
    let(:action_code) { Hackney::Tenancy::ActionCodes::CODES_THAT_PAUSES_CASES.sample }

    it 'will call the add_action_diary and sql_pause_tenancy_gateway with the correct data' do
      add_action_diary_and_sync_case.execute(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username
      )

      allow(add_action_diary_and_sync_case).to receive(:execute)
      expect(sql_pause_tenancy_gateway).to have_received(:set_paused_until).with(
        pause_reason: 'Other',
        pause_comment: "Paused for resync at #{Date.tomorrow}",
        tenancy_ref: tenancy_ref,
        until_date: Date.tomorrow.beginning_of_day.iso8601
      )
      expect(add_action_diary).to have_received(:execute)
    end
  end
end
