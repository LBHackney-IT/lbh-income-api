require 'rails_helper'

describe Hackney::Income::CreateCourtCaseAndSync do
  subject {
    described_class.new(
      create_court_case: create_court_case,
      add_action_diary_and_sync_case_usecase: add_action_diary_and_sync_case_usecase
    )
  }

  let(:add_action_diary_and_sync_case_usecase) { double(UseCases::AddActionDiaryAndSyncCase) }
  let(:create_court_case) { double(Hackney::Income::CreateCourtCase) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:court_date) { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
  let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS }
  let(:balance_on_court_outcome_date) { Faker::Commerce.price(range: 10...100) }
  let(:strike_out_date) { Faker::Date.forward(days: 365) }
  let(:terms) { [true, false].sample }
  let(:disrepair_counter_claim) { [true, false].sample }
  let(:username) { Faker::Name.name }

  let(:new_court_case_params) do
    {
      tenancy_ref: tenancy_ref,
      court_date: court_date,
      court_outcome: court_outcome,
      balance_on_court_outcome_date: balance_on_court_outcome_date,
      strike_out_date: strike_out_date,
      terms: terms,
      disrepair_counter_claim: disrepair_counter_claim
    }
  end

  context 'when a username is provided' do
    it 'calls the create court date usecase and adds to the action diary and re-syncs the case' do
      expect(add_action_diary_and_sync_case_usecase).to receive(:execute).with(
        tenancy_ref: tenancy_ref,
        action_code: 'CDS',
        comment: 'Court case created',
        username: username
      )

      expect(create_court_case).to receive(:execute).with(court_case_params: new_court_case_params)

      subject.execute(court_case_params: new_court_case_params, username: username)
    end
  end

  it 'creates and returns a new court date' do
    expect(add_action_diary_and_sync_case_usecase).not_to receive(:execute).with(
      tenancy_ref: tenancy_ref,
      action_code: 'CDS',
      comment: 'Court case created',
      username: username
    )

    expect(create_court_case).to receive(:execute).with(court_case_params: new_court_case_params)

    subject.execute(court_case_params: new_court_case_params)
  end
end
