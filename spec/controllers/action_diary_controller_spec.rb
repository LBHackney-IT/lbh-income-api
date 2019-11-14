require 'rails_helper'

describe ActionDiaryController, type: :controller do
  let(:action_diary_params) do
    {
      username: Faker::Name.name,
      tenancy_ref: Faker::Lorem.characters(8),
      action_code: Faker::Internet.slug,
      comment: Faker::Lorem.paragraph
    }
  end

  let(:add_action_diary_entry_sync_case_double) { double(UseCases::AddActionDiaryAndSyncCase) }

  before do
    allow(UseCases::AddActionDiaryAndSyncCase).to receive(:new).and_return(add_action_diary_entry_sync_case_double)
    allow(add_action_diary_entry_sync_case_double).to receive(:execute)
  end

  it 'is accessible' do
    assert_generates '/api/v1/tenancies/1234/action_diary', controller: 'action_diary', action: 'create', tenancy_ref: 1234
  end

  context 'when receiving valid params' do
    it 'passes the correct params to the add action diary entry use case' do
      expect(add_action_diary_entry_sync_case_double).to receive(:execute)
        .with(action_diary_params)
        .and_return(nil)
        .once

      post :create, params: action_diary_params
    end

    it 'returns a 200 response' do
      expect(add_action_diary_entry_sync_case_double).to receive(:execute).and_return(nil).once
      patch :create, params: action_diary_params
      expect(response.status).to eq(204)
    end
  end

  context 'when receiving valid params to the sync case priority use case' do
    it 'passes the correct params to the use case' do
      expect(add_action_diary_entry_sync_case_double).to receive(:execute)
        .with(action_diary_params)
        .and_return(nil)
        .once

      post :create, params: action_diary_params
    end
  end

  context 'when receiving a username that does not exist' do
    it 'returns a 422 error' do
      expect(add_action_diary_entry_sync_case_double).to receive(:execute)
        .and_raise(ArgumentError.new('username supplied does not exist'))
        .once

      post :create, params: action_diary_params

      expect(response.status).to eq(422)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json).to eq(code: 422, message: 'username supplied does not exist', status: 'error')
    end
  end
end
