require 'swagger_helper'

RSpec.describe 'Actions', type: :request do

  describe 'GET /api/v1/actions' do
    # post "/api/v1/court_case/#{tenancy_ref}", params: new_court_case_params
    path '/actions/' do
      let(:leasehold_action_array) { create_list(:leasehold_action, 2)}

      it 'calls view actions use-case and renders its response' do
        get "/api/v1/actions?service_area=reasons"

        expect(response.status).to eq(200)

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['actions']).to eq(
             {
                balance: 12,
                payment_ref: 1010101202,
                patch_code: "BLA",
                action_type: "Freehold",
                service_area: "Leasehold",
                metadata: {
                    address: "1 Hillman St, Hackney, London E8 1DY",
                    lessee: "Idris Elba",
                    tenure: "Freehold",
                    direct_debit_status: "Live",
                    latest_letter: nil,
                    letter_date: nil
                }
            }
         )
      end
    end
  end
end
