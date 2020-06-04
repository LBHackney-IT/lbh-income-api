require 'rails_helper'

describe CasesController do
  describe '#index' do
    let(:view_my_cases_instance) { instance_double(Hackney::Income::ViewCases) }

    before do
      allow(Hackney::Income::ViewCases).to receive(:new).with(
        tenancy_api_gateway: instance_of(Hackney::Tenancy::Gateway::TenanciesGateway),
        stored_tenancies_gateway: instance_of(Hackney::Income::StoredTenanciesGateway)
      ).and_return(view_my_cases_instance)
    end

    it 'throws exception when required params not supplied' do
      expect { get :index }.to raise_error(ActionController::ParameterMissing)
    end

    context 'when a page number or number of results per page requested is less than 1' do
      it 'min of 1 should be used' do
        allow(view_my_cases_instance)
          .to receive(:execute)
          .with(page_number: 1, number_per_page: 1, filters: {
            is_paused: nil,
            pause_reason: nil,
            classification: nil,
            patch: nil,
            full_patch: nil,
            upcoming_evictions: nil,
            upcoming_court_dates: nil
          })

        get :index, params: { page_number: 0, number_per_page: 0 }
      end
    end

    context 'when retrieving paused cases filtered by paused reason' do
      let(:pause_reason) { Faker::Lorem.word }

      it 'pause reason should be passed to the use case' do
        allow(view_my_cases_instance)
          .to receive(:execute)
          .with(page_number: 1, number_per_page: 1, filters: {
            classification: nil,
            patch: nil,
            full_patch: nil,
            upcoming_evictions: nil,
            upcoming_court_dates: nil,
            is_paused: true,
            pause_reason: pause_reason
          })

        get :index, params: { is_paused: true, pause_reason: pause_reason, number_per_page: 1, page_number: 1 }
      end
    end

    context 'when retrieving cases' do
      let(:page_number) { Faker::Number.number(digits: 2).to_i }
      let(:number_per_page) { Faker::Number.number(digits: 2).to_i }
      let(:patch) { Faker::Lorem.characters(number: 3) }

      it 'creates the view my cases use case' do
        allow(view_my_cases_instance)
          .to receive(:execute)
          .and_return(cases: [], number_per_page: 1)

        get :index, params: { page_number: page_number, number_per_page: number_per_page }
      end

      it 'calls the view my cases use case with the given page_number and number_per_page' do
        allow(view_my_cases_instance)
          .to receive(:execute)
          .with(page_number: page_number, number_per_page: number_per_page, filters: {
            is_paused: nil,
            classification: nil,
            patch: nil,
            full_patch: nil,
            upcoming_evictions: nil,
            upcoming_court_dates: nil,
            pause_reason: nil
          })
          .and_return(cases: [], number_per_page: 1)

        get :index, params: { page_number: page_number, number_per_page: number_per_page }
      end

      it 'responds with the results of the view my cases use case' do
        expected_result = {
          cases: [Faker::GreekPhilosophers.quote],
          number_per_page: 10
        }

        allow(view_my_cases_instance)
          .to receive(:execute)
          .and_return(expected_result)

        get :index, params: { page_number: page_number, number_per_page: number_per_page }

        expect(response.body).to eq(expected_result.to_json)
      end

      it 'responds with only non paused results when requested' do
        expected_result = {
          cases: [Faker::GreekPhilosophers.quote],
          number_per_page: number_per_page
        }

        allow(view_my_cases_instance)
          .to receive(:execute)
          .with(page_number: page_number, number_per_page: number_per_page, filters: {
            is_paused: false,
            pause_reason: nil,
            classification: nil,
            patch: nil,
            full_patch: nil,
            upcoming_evictions: nil,
            upcoming_court_dates: nil
          })
          .and_return(expected_result)

        get :index, params: { page_number: page_number, number_per_page: number_per_page, is_paused: false }

        expect(response.body).to eq(expected_result.to_json)
      end

      it 'responds with results filtered by patch when requested' do
        expected_result = {
          cases: [Faker::GreekPhilosophers.quote],
          number_per_page: number_per_page
        }

        allow(view_my_cases_instance)
          .to receive(:execute)
          .with(page_number: page_number, number_per_page: number_per_page, filters: {
            is_paused: nil,
            pause_reason: nil,
            classification: nil,
            patch: patch,
            full_patch: nil,
            upcoming_evictions: nil,
            upcoming_court_dates: nil
          })
          .and_return(expected_result)

        get :index, params: { page_number: page_number, number_per_page: number_per_page, patch: patch }

        expect(response.body).to eq(expected_result.to_json)
      end
    end
  end

  describe '#sync' do
    it 'creates the sync tenancies use case' do
      expect(Hackney::Income::ScheduleSyncCases).to receive(:new).with(
        uh_tenancies_gateway: instance_of(Hackney::Income::UniversalHousingTenanciesGateway),
        background_job_gateway: instance_of(Hackney::Income::BackgroundJobGateway)
      ).and_call_original

      allow_any_instance_of(Hackney::Income::ScheduleSyncCases)
        .to receive(:execute)
        .and_return(cases: [], number_per_page: 1)

      get :sync
    end

    it 'calls the sync tenancies use case' do
      expect_any_instance_of(Hackney::Income::ScheduleSyncCases)
        .to receive(:execute)
        .and_return(cases: [], number_per_page: 1)

      get :sync
    end

    it 'responds with { success: true }' do
      allow_any_instance_of(Hackney::Income::ScheduleSyncCases)
        .to receive(:execute)
        .and_return(cases: [], number_per_page: 1)

      get :sync

      expect(response.body).to eq({ success: true }.to_json)
    end
  end
end
