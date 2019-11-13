require 'rails_helper'

describe ActionDiaryController, type: :controller do
  let(:action_diary_params) do
    {
      username: Faker::Name.name,
      tenancy_ref: Faker::Lorem.characters(8),
      action_code: Faker::Internet.slug,
      comment: 'George was here'
    }
  end

  let(:use_case_double) { double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:sync_case_priority_double) { double(Hackney::Income::SyncCasePriority) }

  before do
    stub_const('Hackney::Tenancy::AddActionDiaryEntry', use_case_double)
    allow(use_case_double).to receive(:new).and_return(use_case_double)
    allow(use_case_double).to receive(:execute)

    stub_const('Hackney::Income::SyncCasePriority', sync_case_priority_double)
    allow(sync_case_priority_double).to receive(:new).and_return(sync_case_priority_double)
    allow(sync_case_priority_double).to receive(:execute)
  end

  it 'is accessible' do
    assert_generates '/api/v1/tenancies/1234/action_diary', controller: 'action_diary', action: 'create', tenancy_ref: 1234
  end

  context 'when receiving valid params' do
    it 'passes the correct params to the add action diary entry use case' do
      expect(use_case_double).to receive(:execute)
        .with(action_diary_params)
        .and_return(nil)
        .once

      patch :create, params: action_diary_params
    end

    it 'returns a 200 response' do
      expect(use_case_double).to receive(:execute).and_return(nil).once
      patch :create, params: action_diary_params
      expect(response.status).to eq(204)
    end
  end

  context 'when receiving valid params to the sync case priority use case' do
    it 'passes the correct params to the use case' do
      expect(sync_case_priority_double).to receive(:execute)
        .with(tenancy_ref: action_diary_params[:tenancy_ref])
        .and_return(nil)
        .once

      patch :create, params: action_diary_params
    end
  end

  context 'when receiving a username that does not exist' do
    it 'returns a 422 error' do
      expect(use_case_double).to receive(:execute)
        .and_raise(ArgumentError.new('username supplied does not exist'))
        .once

      patch :create, params: action_diary_params

      expect(response.status).to eq(422)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json).to eq(code: 422, message: 'username supplied does not exist', status: 'error')
    end
  end
end
