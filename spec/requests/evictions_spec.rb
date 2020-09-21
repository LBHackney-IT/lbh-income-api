require 'swagger_helper'

RSpec.describe 'Evictions', type: :request do
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:date) { Faker::Date.between(from: 2.days.ago, to: Date.today).to_s }

  describe 'POST /api/v1/eviction/{tenancy_ref}' do
    path '/eviction/{tenancy_ref}' do
      context 'when creating a new eviction' do
        let(:create_eviction_instance) { instance_double(Hackney::Income::CreateEviction) }
        let(:new_eviction_params) do
          {
            tenancy_ref: tenancy_ref,
            date: date
          }
        end

        let(:created_eviction) { create(:eviction, new_eviction_params) }

        before do
          allow(Hackney::Income::CreateEviction).to receive(:new).and_return(create_eviction_instance)
          allow(create_eviction_instance).to receive(:execute)
            .with(eviction_params: new_eviction_params)
            .and_return(created_eviction)
        end

        it 'creates a new eviction for the given tenancy_ref' do
          post "/api/v1/eviction/#{tenancy_ref}", params: new_eviction_params

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['tenancyRef']).to eq(tenancy_ref)
          expect(parsed_response['date']).to include(date)
        end
      end
    end
  end

  describe 'GET /api/v1/eviction/{tenancy_ref}' do
    path '/evictions/{tenancy_ref}' do
      let(:view_evictions_instance) { instance_double(Hackney::Income::ViewEvictions) }
      let(:evictions_array) { create_list(:eviction, 3, tenancy_ref: tenancy_ref) }

      before do
        allow(Hackney::Income::ViewEvictions).to receive(:new).and_return(view_evictions_instance)
        allow(view_evictions_instance).to receive(:execute)
          .with(tenancy_ref: tenancy_ref)
          .and_return(evictions_array)
      end

      it 'calls ViewEvictions and renders its response' do
        get "/api/v1/evictions/#{tenancy_ref}"

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['evictions'].count).to eq(3)
        parsed_response['evictions'].each do |eviction|
          expect(eviction['tenancyRef']).to eq(tenancy_ref)
        end
      end
    end
  end
end
