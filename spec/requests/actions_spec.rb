require 'swagger_helper'

RSpec.describe 'Actions', type: :request do

  describe 'GET /api/v1/actions' do
    # post "/api/v1/court_case/#{tenancy_ref}", params: new_court_case_params
    path '/actions/' do
      let!(:leasehold_action_array) { create_list(:leasehold_action, 2)}

      # before do
      #   create_list(:leasehold_action, 2)
      # end

      it 'calls view actions use-case and renders its response' do
        get "/api/v1/actions?service_area=reasons"

        expect(response.status).to eq(200)

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['actions']).to eq(leasehold_action_array.to_json)
      end
    end
  end
end
