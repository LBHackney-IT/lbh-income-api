require 'swagger_helper'

RSpec.describe 'GET /api/v1/agreements/{tenancy_ref}', type: :request do
  path '/agreements/{tenancy_ref}' do
    it 'returns all agreements with the given tenancy_ref' do
      tenancy_ref = '123'
      Hackney::Income::Models::Agreement.create!(tenancy_ref: tenancy_ref)

      get "/api/v1/agreements/#{tenancy_ref}"

      parsed_response = JSON.parse(response.body)
      expect(parsed_response['agreements'].count).to eq(1)
      expect(parsed_response['agreements'].first['tenancyRef']).to eq(tenancy_ref)
    end
  end
end
