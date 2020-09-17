require 'swagger_helper'

RSpec.describe 'EvictionDates', type: :request do
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:eviction_date) { Faker::Date.between(from: 2.days.ago, to: Date.today).to_s }

  describe 'POST /api/v1/eviction_date/{tenancy_ref}' do
    path '/eviction_date/{tenancy_ref}' do
      context 'when creating a new eviction date' do
        let(:create_eviction_date_instance) { instance_double(Hackney::Income::CreateEvictionDate) }
        let(:new_eviction_date_params) do
          {
            tenancy_ref: tenancy_ref,
            eviction_date: eviction_date
          }
        end

        let(:created_eviction_date) { create(:eviction_date, new_eviction_date_params) }

        before do
          allow(Hackney::Income::CreateEvictionDate).to receive(:new).and_return(create_eviction_date_instance)
          allow(create_eviction_date_instance).to receive(:execute)
            .with(eviction_date_params: new_eviction_date_params)
            .and_return(created_eviction_date)
        end

        it 'creates a new eviction date for the given tenancy_ref' do
          post "/api/v1/eviction_date/#{tenancy_ref}", params: new_eviction_date_params

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['tenancyRef']).to eq(tenancy_ref)
          expect(parsed_response['evictionDate']).to include(eviction_date)
        end
      end
    end
  end

  describe 'GET /api/v1/eviction_date/{tenancy_ref}' do
    path '/eviction_dates/{tenancy_ref}' do
      let(:view_eviction_dates_instance) { instance_double(Hackney::Income::ViewEvictionDates) }
      let(:eviction_dates_array) { create_list(:eviction_date, 3, tenancy_ref: tenancy_ref) }

      before do
        allow(Hackney::Income::ViewEvictionDates).to receive(:new).and_return(view_eviction_dates_instance)
        allow(view_eviction_dates_instance).to receive(:execute)
          .with(tenancy_ref: tenancy_ref)
          .and_return(eviction_dates_array)
      end

      it 'calls ViewEvictionDates and renders its response' do
        get "/api/v1/eviction_dates/#{tenancy_ref}"

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['evictionDates'].count).to eq(3)
        parsed_response['evictionDates'].each do |court_case|
          expect(court_case['tenancyRef']).to eq(tenancy_ref)
        end
      end
    end
  end
end
