require 'rails_helper'

describe Hackney::Income::UpdateCourtCaseAndSync do
  subject {
    described_class.new(
      update_court_case: update_court_case,
      add_action_diary_and_sync_case: add_action_diary_and_sync_case_usecase
    )
  }

  let(:update_court_case) { instance_double(Hackney::Income::UpdateCourtCase) }
  let(:add_action_diary_and_sync_case_usecase) { instance_double(UseCases::AddActionDiaryAndSyncCase) }

  let(:id) { Faker::Number.number(digits: 2) }
  let(:tenancy_ref) { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
  let(:court_date) { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
  let(:court_outcome) { Hackney::Tenancy::UpdatedCourtOutcomeCodes::STRUCK_OUT }
  let(:balance_on_court_outcome_date) { Faker::Commerce.price(range: 10...100) }
  let(:strike_out_date) { nil }
  let(:terms) { nil }
  let(:disrepair_counter_claim) { nil }
  let(:username) { Faker::Name.name }

  let(:court_case_params) do
    {
      id: id,
      tenancy_ref: tenancy_ref,
      court_date: court_date,
      court_outcome: court_outcome,
      balance_on_court_outcome_date: balance_on_court_outcome_date,
      strike_out_date: strike_out_date,
      terms: terms,
      disrepair_counter_claim: disrepair_counter_claim
    }
  end

  let(:court_case) { build_stubbed(:court_case, court_case_params) }

  context 'when provided with a username' do
    it 'calls the update court case usecase, adds an action diary, syncs the case' do
      expect(update_court_case).to receive(:execute).with(
        court_case_params: court_case_params
      ).and_return(court_case)

      expect(add_action_diary_and_sync_case_usecase).to receive(:execute)
        .with(
          username: username,
          tenancy_ref: tenancy_ref,
          action_code: 'IC6',
          comment: 'Court outcome added: Struck out'
        )
        .once

      updated_court_case = subject.execute(court_case_params: court_case_params, username: username)

      expect(updated_court_case).to be_an_instance_of(Hackney::Income::Models::CourtCase)
    end
  end

  context 'when not provided with a username' do
    it 'calls the update court case usecase and returns the updated court case' do
      expect(update_court_case).to receive(:execute).with(
        court_case_params: court_case_params
      ).and_return(court_case)

      expect(add_action_diary_and_sync_case_usecase).not_to receive(:execute)
        .with(
          username: username,
          tenancy_ref: tenancy_ref,
          action_code: 'IC6',
          comment: 'Court outcome added: Struck out'
        )

      updated_court_case = subject.execute(court_case_params: court_case_params)

      expect(updated_court_case).to be_an_instance_of(Hackney::Income::Models::CourtCase)
    end
  end
end
