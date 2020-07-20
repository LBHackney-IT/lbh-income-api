require 'swagger_helper'

RSpec.describe 'CourtCases', type: :request do
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:court_decision_date) { Faker::Date.between(from: 2.days.ago, to: Date.today).to_s }
  let(:court_outcome) { Faker::ChuckNorris.fact }
  let(:balance_at_outcome_date) { Faker::Commerce.price(range: 10...100) }

  describe 'POST /api/v1/court_case/{tenancy_ref}' do
    path '/court_case/{tenancy_ref}' do
      let(:create_court_case_instance) { instance_double(Hackney::Income::CreateCourtCase) }
      let(:new_court_case_params) do
        {
          tenancy_ref: tenancy_ref,
          court_decision_date: court_decision_date,
          court_outcome: court_outcome,
          balance_at_outcome_date: balance_at_outcome_date.to_s
        }
      end

      let(:created_court_case) do
        Hackney::Income::Models::CourtCase.create(new_court_case_params)
      end

      before do
        allow(Hackney::Income::CreateCourtCase).to receive(:new).and_return(create_court_case_instance)
        allow(create_court_case_instance).to receive(:execute)
          .with(court_case_params: new_court_case_params)
          .and_return(created_court_case)
      end

      it 'creates a new active court_case for the given tenancy_ref' do
        post "/api/v1/court_case/#{tenancy_ref}", params: new_court_case_params

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['tenancyRef']).to eq(tenancy_ref)
        expect(parsed_response['courtDecisionDate']).to include(court_decision_date)
        expect(parsed_response['courtOutcome']).to eq(court_outcome)
        expect(parsed_response['balanceAtOutcomeDate']).to eq(balance_at_outcome_date)
        expect(parsed_response['createdAt']).to include(Date.today.to_s)
      end
    end
  end
end
