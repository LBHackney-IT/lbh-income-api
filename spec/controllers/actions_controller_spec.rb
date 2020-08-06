require 'rails_helper'

describe ActionsController do
  describe '#index' do
    let(:fetch_actions_instance) { instance_double(Hackney::Income::FetchActions) }

    before do
      allow(Hackney::Income::FetchActions).to receive(:new).with(
        fetch_actions_gateway: instance_of(Hackney::Income::FetchActionsGateway)
      ).and_return(fetch_actions_instance)
    end

    context 'when getting leasehold actions' do
      it 'throws exception when required params not supplied' do
        expect { get :index }.to raise_error(ActionController::ParameterMissing)
      end

      context 'when a page number or number of results per page requested is less than 1' do
        it 'min of 1 should be used' do
          allow(fetch_actions_instance)
            .to receive(:execute)
            .with(page_number: 1, number_per_page: 10, service_area_type: 'leasehold', filters: {
              is_paused: nil,
              pause_reason: nil,
              classification: nil,
              patch: nil,
              full_patch: nil
            })

          get :index, params: { page_number: 0, number_per_page: 0, service_area_type: 'leasehold' }
        end
      end

      context 'when retrieving paused actions filtered by paused reason' do
        let(:pause_reason) { Faker::Lorem.word }

        it 'pause reason should be passed to the use case' do
          allow(fetch_actions_instance)
            .to receive(:execute)
            .with(page_number: 1, number_per_page: 10, service_area_type: 'leasehold', filters: {
              classification: nil,
              patch: nil,
              full_patch: nil,
              is_paused: true,
              pause_reason: pause_reason
            })

          get :index, params: {
            is_paused: true,
            service_area_type: 'leasehold',
            pause_reason: pause_reason,
            number_per_page: 1,
            page_number: 1
          }
        end
      end

      context 'when retrieving actions' do
        let(:page_number) { Faker::Number.number(digits: 2).to_i }
        let(:number_per_page) { Faker::Number.number(digits: 2).to_i }
        let(:patch) { Faker::Lorem.characters(number: 3) }

        it 'creates fetch actions use case' do
          allow(fetch_actions_instance)
            .to receive(:execute)
            .and_return(actions: [], number_per_page: 1)

          get :index, params: { page_number: page_number, number_per_page: number_per_page, service_area_type: 'leasehold' }
        end

        it 'calls the fetch actions use case with the given page_number and number_per_page' do
          allow(fetch_actions_instance)
            .to receive(:execute)
            .with(
              page_number: page_number,
              number_per_page: number_per_page,
              service_area_type: 'leasehold',
              filters: {
                is_paused: nil,
                classification: nil,
                patch: nil,
                full_patch: nil,
                pause_reason: nil
              }
            )
            .and_return(actions: [], number_per_page: 1)

          get :index, params: { page_number: page_number, number_per_page: number_per_page, service_area_type: 'leasehold' }
        end

        it 'responds with the results of the fetch actions use case' do
          expected_result = {
            actions: [Faker::GreekPhilosophers.quote],
            number_per_page: 10
          }

          allow(fetch_actions_instance)
            .to receive(:execute)
            .and_return(expected_result)

          get :index, params: { page_number: page_number, number_per_page: number_per_page, service_area_type: 'leasehold' }

          expect(response.body).to eq(expected_result.to_json)
        end

        it 'responds with only non paused results when requested' do
          expected_result = {
            actions: [Faker::GreekPhilosophers.quote],
            number_per_page: number_per_page
          }

          allow(fetch_actions_instance)
            .to receive(:execute)
            .with(
              page_number: page_number,
              number_per_page: number_per_page,
              service_area_type: 'leasehold',
              filters: {
                classification: nil,
                full_patch: nil,
                is_paused: false,
                patch: nil,
                pause_reason: nil
              }
            )
            .and_return(expected_result)

          get :index, params: {
            page_number: page_number,
            number_per_page: number_per_page,
            is_paused: false,
            service_area_type: 'leasehold'
          }

          expect(response.body).to eq(expected_result.to_json)
        end

        it 'responds with results filtered by patch when requested' do
          expected_result = {
            actions: [Faker::GreekPhilosophers.quote],
            number_per_page: number_per_page
          }

          allow(fetch_actions_instance)
            .to receive(:execute)
            .with(
              page_number: page_number,
              number_per_page: number_per_page,
              service_area_type: 'leasehold',
              filters: {
                classification: nil,
                full_patch: nil,
                is_paused: nil,
                patch: patch,
                pause_reason: nil
              }
            ).and_return(expected_result)

          get :index, params: {
            page_number: page_number,
            number_per_page: number_per_page,
            patch: patch,
            service_area_type: 'leasehold'
          }

          expect(response.body).to eq(expected_result.to_json)
        end
      end
    end
  end
end
