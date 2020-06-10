require 'swagger_helper'

RSpec.describe 'GET /api/v1/agreements/{tenancy_ref}', type: :request do
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

RSpec.describe 'POST /api/v1/agreement/{tenancy_ref}', type: :request do
  path '/agreement/{tenancy_ref}' do
    it 'creates an agreement for the given tenancy_ref' do
      tenancy_ref = '123'

      post "/api/v1/agreement/#{tenancy_ref}", params: {
        agreement_type: 'informal',
        amount: '100',
        start_date: '10-06-2020',
        frequency: 'weekly'
      }

      parsed_response = JSON.parse(response.body)
      expect(parsed_response['tenancyRef']).to eq(tenancy_ref)
    end
  end
end
