require 'swagger_helper'

RSpec.describe 'Agreements', type: :request do
  describe 'GET /api/v1/agreements/{tenancy_ref}' do
    path '/agreements/{tenancy_ref}' do
      let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
      let(:agreement_type) { 'formal' }
      let(:starting_balance) { Faker::Commerce.price(range: 10...1000) }
      let(:amount) { Faker::Commerce.price(range: 10...100) }
      let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
      let(:frequency) { 'weekly' }
      let(:current_state) { 'active' }
      let(:agreements_response) do
        {
          agreements: [
            {
              id: 1,
              tenancyRef: tenancy_ref,
              agreementType: agreement_type,
              startingBalance: starting_balance,
              amount: amount,
              startDate: start_date,
              frequency: frequency,
              currentState: current_state,
              history: []
            }
          ]
        }.to_json
      end

      before do
        allow(Hackney::Income::ViewAgreements).to receive(:execute)
          .with(tenancy_ref: tenancy_ref)
          .and_return(agreements_response)
      end

      it 'calls view agreements use-case and renders its response' do
        get "/api/v1/agreements/#{tenancy_ref}"

        expect(response.status).to eq(200)

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['agreements'].count).to eq(1)
        expect(parsed_response['agreements'].first['tenancyRef']).to eq(tenancy_ref)
        expect(parsed_response['agreements'].first['agreementType']).to eq(agreement_type)
        expect(parsed_response['agreements'].first['startingBalance']).to eq(starting_balance)
        expect(parsed_response['agreements'].first['amount']).to eq(amount)
        expect(parsed_response['agreements'].first['startDate']).to eq(start_date.to_s)
        expect(parsed_response['agreements'].first['frequency']).to eq(frequency)
        expect(parsed_response['agreements'].first['currentState']).to eq(current_state)
        expect(parsed_response['agreements'].first['history']).to eq([])
      end
    end
  end

  describe 'POST /api/v1/agreement/{tenancy_ref}' do
    path '/agreement/{tenancy_ref}' do
      let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
      let(:agreement_type) { 'informal' }
      let(:amount) { Faker::Commerce.price(range: 10...100) }
      let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
      let(:frequency) { 'weekly' }
      let(:current_state) { 'active' }

      let(:new_agreement_params) do
        {
          tenancy_ref: tenancy_ref,
          agreement_type: agreement_type,
          amount: amount.to_s,
          start_date: start_date.to_s,
          frequency: frequency
        }
      end

      let(:create_agreement_response) do
        {
          id: 1,
          tenancyRef: tenancy_ref,
          agreementType: agreement_type,
          # TODO: starting_balance
          amount: amount,
          startDate: start_date,
          frequency: frequency,
          currentState: current_state,
          history: []
        }
      end

      before do
        allow(Hackney::Income::CreateAgreement).to receive(:execute)
          .with(new_agreement_params: new_agreement_params)
          .and_return(create_agreement_response)
      end

      it 'creates a new active agreement for the given tenancy_ref' do
        params = {
          agreement_type: agreement_type,
          amount: amount,
          start_date: start_date,
          frequency: frequency
        }

        post "/api/v1/agreement/#{tenancy_ref}", params: params

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['tenancyRef']).to eq(tenancy_ref)
        expect(parsed_response['agreementType']).to eq(agreement_type)
        # TODO: starting_balance
        expect(parsed_response['amount']).to eq(amount)
        expect(parsed_response['startDate']).to eq(start_date.to_s)
        expect(parsed_response['frequency']).to eq(frequency)
        expect(parsed_response['currentState']).to eq('active')
        expect(parsed_response['history']).to eq([])
      end
    end
  end
end
