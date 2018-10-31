require 'rails_helper'

describe MyCasesController do
  describe '#index' do
    let(:view_my_cases_instance) { instance_double(Hackney::Income::ViewMyCases) }

    before do
      allow(Hackney::Income::ViewMyCases).to receive(:new).with(
        tenancy_api_gateway: instance_of(Hackney::Income::TenancyApiGateway),
        stored_tenancies_gateway: instance_of(Hackney::Income::StoredTenanciesGateway)
      ).and_return(view_my_cases_instance)
    end

    it 'throws exception when required params not supplied' do
      expect { get :index }.to raise_error(ActionController::ParameterMissing)
    end

    context 'when a page numebr or number of results per page requested is less than 1' do
      let(:user_id) { Faker::Number.number(2).to_i }

      it 'min of 1 should be used' do
        allow(view_my_cases_instance)
          .to receive(:execute)
          .with(user_id: user_id, page_number: 1, number_per_page: 1, is_paused: nil)

        get :index, params: { user_id: user_id, page_number: 0, number_per_page: 0 }
      end
    end

    context 'when retrieving cases' do
      let(:user_id) { Faker::Number.number(2).to_i }
      let(:page_number) { Faker::Number.number(2).to_i }
      let(:number_per_page) { Faker::Number.number(2).to_i }

      it 'should create the view my cases use case' do
        allow(view_my_cases_instance)
          .to receive(:execute)
          .and_return(cases: [], number_per_page: 1)

        get :index, params: { user_id: user_id, page_number: page_number, number_per_page: number_per_page }
      end

      it 'should call the view my cases use case with the given user_id, page_number and number_per_page' do
        allow(view_my_cases_instance)
          .to receive(:execute)
          .with(user_id: user_id, page_number: page_number, number_per_page: number_per_page, is_paused: nil)
          .and_return(cases: [], number_per_page: 1)

        get :index, params: { user_id: user_id, page_number: page_number, number_per_page: number_per_page }
      end

      it 'should respond with the results of the view my cases use case' do
        expected_result = {
          cases: [Faker::GreekPhilosophers.quote],
          number_per_page: 10
        }

        allow(view_my_cases_instance)
          .to receive(:execute)
          .and_return(expected_result)

        get :index, params: { user_id: user_id, page_number: page_number, number_per_page: number_per_page }

        expect(response.body).to eq(expected_result.to_json)
      end

      it 'should respond with only non paused results when requested' do
        expected_result = {
          cases: [Faker::GreekPhilosophers.quote],
          number_per_page: number_per_page
        }

        allow(view_my_cases_instance)
          .to receive(:execute)
          .with(user_id: user_id, page_number: page_number, number_per_page: number_per_page, is_paused: false)
          .and_return(expected_result)

        get :index, params: { user_id: user_id, page_number: page_number, number_per_page: number_per_page, is_paused: false }

        expect(response.body).to eq(expected_result.to_json)
      end
    end
  end

  describe '#sync' do
    it 'should create the sync tenancies use case' do
      expect(Hackney::Income::SyncCases).to receive(:new).with(
        uh_tenancies_gateway: instance_of(Hackney::Income::UniversalHousingTenanciesGateway),
        background_job_gateway: instance_of(Hackney::Income::BackgroundJobGateway)
      ).and_call_original

      allow_any_instance_of(Hackney::Income::SyncCases)
        .to receive(:execute)
        .and_return(cases: [], number_per_page: 1)

      get :sync
    end

    it 'should call the sync tenancies use case' do
      expect_any_instance_of(Hackney::Income::SyncCases)
        .to receive(:execute)
        .and_return(cases: [], number_per_page: 1)

      get :sync
    end

    it 'should respond with { success: true }' do
      allow_any_instance_of(Hackney::Income::SyncCases)
        .to receive(:execute)
        .and_return(cases: [], number_per_page: 1)

      get :sync

      expect(response.body).to eq({ success: true }.to_json)
    end
  end
end
