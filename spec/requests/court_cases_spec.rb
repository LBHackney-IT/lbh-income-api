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

  # describe 'POST /api/v1/agreements/{agreement_id}/cancel' do
  #   path '/agreements/{agreement_id}/cancel' do
  #     let(:cancel_agreement_instance) { instance_double(Hackney::Income::CancelAgreement) }
  #     let(:agreement_params) do
  #       {
  #         tenancy_ref: tenancy_ref,
  #         agreement_type: agreement_type,
  #         amount: amount.to_s,
  #         start_date: start_date.to_s,
  #         frequency: frequency,
  #         created_by: created_by,
  #         starting_balance: starting_balance
  #       }
  #     end
  #     let(:agreement) { Hackney::Income::Models::Agreement.create(agreement_params) }

  #     before do
  #       Hackney::Income::Models::AgreementState.create(agreement_id: agreement.id, agreement_state: 'cancelled')

  #       allow(Hackney::Income::CancelAgreement).to receive(:new).and_return(cancel_agreement_instance)
  #       allow(cancel_agreement_instance).to receive(:execute)
  #         .with(agreement_id: agreement.id.to_s)
  #         .and_return(agreement)
  #     end

  #     it 'calls the cancel agreement use-case and returns the cancelled agreement' do
  #       post "/api/v1/agreements/#{agreement.id}/cancel"

  #       parsed_response = JSON.parse(response.body)

  #       expect(parsed_response['tenancyRef']).to eq(tenancy_ref)
  #       expect(parsed_response['agreementType']).to eq(agreement_type)
  #       expect(parsed_response['startingBalance']).to eq(starting_balance)
  #       expect(parsed_response['amount']).to eq(amount)
  #       expect(parsed_response['startDate']).to include(start_date.to_s)
  #       expect(parsed_response['frequency']).to eq(frequency)
  #       expect(parsed_response['currentState']).to eq('cancelled')
  #       expect(parsed_response['createdAt']).to eq(Date.today.to_s)
  #       expect(parsed_response['createdBy']).to eq(created_by)
  #       expect(parsed_response['history'].last['state']).to eq('cancelled')
  #     end

  #     context 'when the agreement does not exist it returns 404' do
  #       let(:cancel_agreement_instance) { instance_double(Hackney::Income::CancelAgreement) }

  #       before do
  #         allow(Hackney::Income::CancelAgreement).to receive(:new).and_return(cancel_agreement_instance)
  #         allow(cancel_agreement_instance).to receive(:execute)
  #           .with(agreement_id: 'N0PE')
  #           .and_return(nil)
  #       end

  #       it 'returns 404' do
  #         post '/api/v1/agreements/N0PE/cancel'

  #         expect(response).to have_http_status(:not_found)
  #         expect(JSON.parse(response.body)['error']).to eq('agreement not found')
  #       end
  #     end
  #   end
  # end
end
