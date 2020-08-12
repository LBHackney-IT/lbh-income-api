require 'swagger_helper'

RSpec.describe 'CourtCases', type: :request do
  let(:id) { Faker::Number.number(digits: 3).to_s }
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:court_date) { Faker::Date.between(from: 2.days.ago, to: Date.today).to_s }
  let(:court_outcome) { 'MAA' }
  let(:balance_on_court_outcome_date) { Faker::Commerce.price(range: 10...100) }
  let(:strike_out_date) { Faker::Date.forward(days: 365).to_s }
  let(:terms) { false }
  let(:disrepair_counter_claim) { false }

  describe 'POST /api/v1/court_case/{tenancy_ref}' do
    path '/court_case/{tenancy_ref}' do
      context 'when creating a new court case by adding a court date'
      let(:create_court_case_instance) { instance_double(Hackney::Income::CreateCourtCase) }
      let(:new_court_case_params) do
        {
          tenancy_ref: tenancy_ref,
          court_date: court_date,
          court_outcome: nil,
          balance_on_court_outcome_date: nil,
          strike_out_date: nil,
          terms: nil,
          disrepair_counter_claim: nil
        }
      end

      let(:created_court_case) { create(:court_case, new_court_case_params) }

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
        expect(parsed_response['courtDate']).to include(court_date)
      end
    end
  end

  describe 'GET /api/v1/court_cases/{tenancy_ref}' do
    path '/court_cases/{tenancy_ref}' do
      let(:view_court_cases_instance) { instance_double(Hackney::Income::ViewCourtCases) }
      let(:court_cases_array) { create_list(:court_case, 3, tenancy_ref: tenancy_ref) }

      before do
        allow(Hackney::Income::ViewCourtCases).to receive(:new).and_return(view_court_cases_instance)
        allow(view_court_cases_instance).to receive(:execute)
          .with(tenancy_ref: tenancy_ref)
          .and_return(court_cases_array)
      end

      it 'calls ViewCourtCases use-case and renders its response' do
        get "/api/v1/court_cases/#{tenancy_ref}"

        expect(response.status).to eq(200)

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['court_cases'].count).to eq(3)
        parsed_response['court_cases'].each do |court_case|
          expect(court_case['tenancyRef']).to eq(tenancy_ref)
        end
      end
    end
  end

  describe 'PATCH /api/v1/court_case/{tenancy_ref}' do
    path '/court_case/{court_case_id}/update' do
      let(:update_court_case_instance) { instance_double(Hackney::Income::UpdateCourtCase) }
      let(:existing_court_case) { create(:court_case, id: id, tenancy_ref: tenancy_ref, court_date: court_date) }

      context 'when adding a (not adjourned) court outcome' do
        let(:update_court_case_params) do
          {
            id: id,
            court_date: court_date,
            court_outcome: court_outcome,
            balance_on_court_outcome_date: balance_on_court_outcome_date.to_s,
            strike_out_date: nil,
            terms: nil,
            disrepair_counter_claim: nil
          }
        end

        let(:updated_court_case) { create(:court_case, update_court_case_params) }

        before do
          allow(Hackney::Income::UpdateCourtCase).to receive(:new).and_return(update_court_case_instance)
          allow(update_court_case_instance).to receive(:execute)
            .with(court_case_params: update_court_case_params)
            .and_return(updated_court_case)
        end

        it 'updates the court case' do
          patch "/api/v1/court_case/#{id}/update", params: update_court_case_params

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['courtDate']).to include(court_date)
          expect(parsed_response['courtOutcome']).to eq(court_outcome)
          expect(parsed_response['balanceOnCourtOutcomeDate']).to eq(balance_on_court_outcome_date.to_s)
        end
      end

      context 'when adding an adjourned court outcome' do
        let(:court_outcome) { 'AAH' }
        let(:update_court_case_params) do
          {
            id: id,
            court_date: court_date,
            court_outcome: court_outcome,
            balance_on_court_outcome_date: balance_on_court_outcome_date.to_s,
            strike_out_date: strike_out_date,
            terms: terms.to_s,
            disrepair_counter_claim: disrepair_counter_claim.to_s
          }
        end

        let(:updated_court_case) { build(:court_case, update_court_case_params) }

        before do
          allow(Hackney::Income::UpdateCourtCase).to receive(:new).and_return(update_court_case_instance)
          allow(update_court_case_instance).to receive(:execute)
            .with(court_case_params: update_court_case_params)
            .and_return(updated_court_case)
        end

        it 'updates the court case' do
          patch "/api/v1/court_case/#{id}/update", params: update_court_case_params

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['courtDate']).to include(court_date)
          expect(parsed_response['courtOutcome']).to eq(court_outcome)
          expect(parsed_response['balanceOnCourtOutcomeDate']).to eq(balance_on_court_outcome_date.to_s)
          expect(parsed_response['strikeOutDate']).to include(strike_out_date)
          expect(parsed_response['terms']).to eq(terms)
          expect(parsed_response['disrepairCounterClaim']).to eq(disrepair_counter_claim)
        end
      end

      context 'when the court case does not exist' do
        let(:non_existent_id) { '0' }
        let(:update_court_case_params) do
          {
            id: non_existent_id,
            court_date: court_date,
            court_outcome: court_outcome,
            balance_on_court_outcome_date: balance_on_court_outcome_date.to_s,
            strike_out_date: nil,
            terms: nil,
            disrepair_counter_claim: nil
          }
        end

        before do
          allow(Hackney::Income::UpdateCourtCase).to receive(:new).and_return(update_court_case_instance)
          allow(update_court_case_instance).to receive(:execute)
            .with(court_case_params: update_court_case_params)
            .and_return(nil)
        end

        it 'returns 404' do
          patch "/api/v1/court_case/#{non_existent_id}/update", params: update_court_case_params

          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq('court case not found')
        end
      end
    end
  end
end
