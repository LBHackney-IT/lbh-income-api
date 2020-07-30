require 'swagger_helper'

RSpec.describe 'Agreements', type: :request do
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:agreement_type) { 'informal' }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:frequency) { 'weekly' }
  let(:current_state) { 'live' }
  let(:starting_balance) { Faker::Commerce.price(range: 100...1000) }
  let(:created_by) { Faker::Name.name }
  let(:notes) { Faker::ChuckNorris.fact }

  describe 'GET /api/v1/agreements/{tenancy_ref}' do
    path '/agreements/{tenancy_ref}' do
      let(:view_agreements_instance) { instance_double(Hackney::Income::ViewAgreements) }
      let(:agreements_array) do
        [
          create(:agreement,
                 tenancy_ref: tenancy_ref,
                 agreement_type: agreement_type,
                 starting_balance: starting_balance,
                 amount: amount,
                 start_date: start_date,
                 frequency: frequency,
                 current_state: current_state,
                 created_by: created_by,
                 notes: notes)
        ]
      end

      before do
        allow(Hackney::Income::ViewAgreements).to receive(:new).and_return(view_agreements_instance)
        allow(view_agreements_instance).to receive(:execute)
          .with(tenancy_ref: tenancy_ref)
          .and_return(agreements_array)
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
        expect(parsed_response['agreements'].first['startDate']).to include(start_date.to_s)
        expect(parsed_response['agreements'].first['frequency']).to eq(frequency)
        expect(parsed_response['agreements'].first['currentState']).to eq(nil)
        expect(parsed_response['agreements'].first['createdAt']).to eq(Date.today.to_s)
        expect(parsed_response['agreements'].first['createdBy']).to eq(created_by)
        expect(parsed_response['agreements'].first['notes']).to eq(notes)
        expect(parsed_response['agreements'].first['history']).to eq([])
      end

      it 'correctly maps all agreement_states in history' do
        first_state = create(:agreement_state, :live, agreement_id: agreements_array.first.id)
        second_state = create(:agreement_state, :breached, agreement_id: agreements_array.first.id)

        get "/api/v1/agreements/#{tenancy_ref}"

        expect(response.status).to eq(200)

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['agreements'].first['history']).to match([
          {
            'state' => first_state.agreement_state,
            'date' => first_state.created_at.as_json
          },
          {
            'state' => second_state.agreement_state,
            'date' => second_state.created_at.as_json
          }
        ])
      end
    end
  end

  describe 'POST /api/v1/agreement/{tenancy_ref}' do
    path '/agreement/{tenancy_ref}' do
      let(:create_agreement_instance) { instance_double(Hackney::Income::CreateInformalAgreement) }
      let(:new_agreement_params) do
        {
          tenancy_ref: tenancy_ref,
          agreement_type: agreement_type,
          amount: amount.to_s,
          start_date: start_date.to_s,
          frequency: frequency,
          created_by: created_by,
          notes: notes
        }
      end

      let(:created_agreement) do
        create(:agreement,
               starting_balance: starting_balance,
               **new_agreement_params)
      end

      before do
        allow(Hackney::Income::CreateInformalAgreement).to receive(:new).and_return(create_agreement_instance)
        allow(create_agreement_instance).to receive(:execute)
          .with(new_agreement_params: new_agreement_params)
          .and_return(created_agreement)
      end

      it 'creates a new active agreement for the given tenancy_ref' do
        post "/api/v1/agreement/#{tenancy_ref}", params: new_agreement_params

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['tenancyRef']).to eq(tenancy_ref)
        expect(parsed_response['agreementType']).to eq(agreement_type)
        expect(parsed_response['startingBalance']).to eq(starting_balance)
        expect(parsed_response['amount']).to eq(amount)
        expect(parsed_response['startDate']).to include(start_date.to_s)
        expect(parsed_response['frequency']).to eq(frequency)
        expect(parsed_response['currentState']).to eq(nil)
        expect(parsed_response['createdAt']).to eq(Date.today.to_s)
        expect(parsed_response['createdBy']).to eq(created_by)
        expect(parsed_response['notes']).to eq(notes)
        expect(parsed_response['history']).to eq([])
      end
    end
  end

  describe 'POST /api/v1/agreements/{agreement_id}/cancel' do
    path '/agreements/{agreement_id}/cancel' do
      let(:cancel_agreement_instance) { instance_double(Hackney::Income::CancelAgreement) }
      let(:agreement_params) do
        {
          tenancy_ref: tenancy_ref,
          agreement_type: agreement_type,
          amount: amount.to_s,
          start_date: start_date.to_s,
          frequency: frequency,
          created_by: created_by,
          starting_balance: starting_balance
        }
      end
      let(:agreement) { create(:agreement, agreement_params) }

      before do
        create(:agreement_state, :cancelled, agreement_id: agreement.id)

        allow(Hackney::Income::CancelAgreement).to receive(:new).and_return(cancel_agreement_instance)
        allow(cancel_agreement_instance).to receive(:execute)
          .with(agreement_id: agreement.id.to_s)
          .and_return(agreement)
      end

      it 'calls the cancel agreement use-case and returns the cancelled agreement' do
        post "/api/v1/agreements/#{agreement.id}/cancel"

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['tenancyRef']).to eq(tenancy_ref)
        expect(parsed_response['agreementType']).to eq(agreement_type)
        expect(parsed_response['startingBalance']).to eq(starting_balance)
        expect(parsed_response['amount']).to eq(amount)
        expect(parsed_response['startDate']).to include(start_date.to_s)
        expect(parsed_response['frequency']).to eq(frequency)
        expect(parsed_response['currentState']).to eq('cancelled')
        expect(parsed_response['createdAt']).to eq(Date.today.to_s)
        expect(parsed_response['createdBy']).to eq(created_by)
        expect(parsed_response['history'].last['state']).to eq('cancelled')
      end

      context 'when the agreement does not exist it returns 404' do
        let(:cancel_agreement_instance) { instance_double(Hackney::Income::CancelAgreement) }

        before do
          allow(Hackney::Income::CancelAgreement).to receive(:new).and_return(cancel_agreement_instance)
          allow(cancel_agreement_instance).to receive(:execute)
            .with(agreement_id: 'N0PE')
            .and_return(nil)
        end

        it 'returns 404' do
          post '/api/v1/agreements/N0PE/cancel'

          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq('agreement not found')
        end
      end
    end
  end
end
