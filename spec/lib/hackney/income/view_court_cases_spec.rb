require 'rails_helper'

describe Hackney::Income::ViewCourtCases do
  subject { described_class.new.execute(tenancy_ref: tenancy_ref) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  context 'when there are no court cases for the tenancy' do
    it 'returns an empty array' do
      expect(subject).to eq([])
    end
  end

  context 'when there is a court case for the tenancy' do
    let(:balance_at_outcome_date) { Faker::Commerce.price(range: 10...1000) }
    let(:court_decision_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    let(:court_outcome) { Faker::ChuckNorris.fact }
    let(:court_cases_param) do
      {
        tenancy_ref: tenancy_ref,
        balance_at_outcome_date: balance_at_outcome_date,
        court_decision_date: court_decision_date,
        court_outcome: court_outcome
      }
    end

    let!(:expected_court_case) { Hackney::Income::Models::CourtCase.create!(court_cases_param) }

    it 'returns an array of court cases for the given tenancy_ref' do
      response = subject

      expect(response.count).to eq(1)
      expect(response.first.id).to eq(expected_court_case.id)
      expect(response.first.tenancy_ref).to eq(tenancy_ref)
      expect(response.first.balance_at_outcome_date).to eq(balance_at_outcome_date)
      expect(response.first.court_decision_date).to eq(court_decision_date)
      expect(response.first.court_outcome).to eq(court_outcome)
      expect(response.first.agreements).to eq([])
    end

    it 'returns the associated formal agreements' do
      agreement_params =
        {
          tenancy_ref: tenancy_ref,
          agreement_type: :formal,
          created_by: Faker::Name.name,
          court_case_id: expected_court_case.id
        }
      agreement = Hackney::Income::Models::Agreement.create!(agreement_params)
      response = subject

      expect(response.first.agreements).to eq([agreement])
    end
  end
end
