require 'swagger_helper'

RSpec.describe 'Actions', type: :request do
  describe 'GET /api/v1/actions' do
    path '/actions/' do
      context 'when fetching leasehold' do
        let!(:leasehold_action) { create(:leasehold_action) }

        before do
          create(:leasehold_action, service_area_type: :rent)
        end

        it 'calls view actions use-case and renders its response' do
          get '/api/v1/actions?service_area_type=leasehold'

          expect(response.status).to eq(200)

          parsed_body = JSON.parse(response.body)

          expect(parsed_body['actions'].count).to eq(1)

          expected_result = {
            'actions' => [leasehold_action],
            'number_of_pages' => 1
          }.to_json

          expect(parsed_body).to eq(JSON.parse(expected_result))
        end
      end
    end
  end
end
