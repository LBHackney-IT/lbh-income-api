require 'rails_helper'

describe TenanciesController, type: :controller do
  let(:paused_parms) do
    {
      username: Faker::Name.name,
      tenancy_ref: Faker::Lorem.characters(number: 8),
      is_paused_until: Faker::Date.forward(days: 23).to_s,
      pause_reason: Faker::Lorem.sentence,
      pause_comment: Faker::Lorem.paragraph,
      action_code: Faker::Internet.slug
    }
  end
  let(:params2) do
    {
      username: Faker::Name.name,
      tenancy_ref: Faker::Lorem.characters(number: 8),
      is_paused_until: Faker::Date.backward(days: 23).to_s,
      pause_reason: Faker::Lorem.sentence,
      pause_comment: Faker::Lorem.paragraph,
      action_code: Faker::Internet.slug
    }
  end

  let(:dummy_action_diary_usecase) { double(Hackney::Tenancy::AddActionDiaryEntry) }

  before do
    stub_const('Hackney::Income::SqlPauseTenancyGateway', StubSqlPauseTenancyGateway)
    stub_const('Hackney::Tenancy::AddActionDiaryEntry', dummy_action_diary_usecase)
    allow(dummy_action_diary_usecase).to receive(:new).and_return(dummy_action_diary_usecase)
    allow(dummy_action_diary_usecase).to receive(:execute)
  end

  it 'is accessible from /' do
    assert_generates '/api/v1/tenancies/1234', controller: 'tenancies', action: 'update', tenancy_ref: 1234
  end

  context 'when fetching a tenancy' do
    let(:tenancy_1) { create(:case_priority, tenancy_ref: 1234) }

    before do
      tenancy_1.save
    end

    it 'is accessible from /' do
      assert_generates '/api/v1/tenancies/1234', controller: 'tenancies', action: 'show', tenancy_ref: 1234
    end

    it 'returns a tenancy' do
      expect_any_instance_of(Hackney::Income::GetTenancy).to receive(:execute).with(
        tenancy_ref: tenancy_1.tenancy_ref
      ).and_call_original

      get :show, params: { tenancy_ref: tenancy_1.tenancy_ref }

      expect(response.status).to eq(200)

      tenancy_hash = JSON.parse(response.body, symbolize_names: true)

      expect(tenancy_hash).to match(
        a_hash_including(
          id: tenancy_1.id,
          tenancy_ref: tenancy_1.tenancy_ref,
          active_nosp: nil,
          assigned_user_id: nil,
          balance: tenancy_1.balance.to_s,
          case_id: tenancy_1.case_id,
          classification: nil,
          court_outcome: nil,
          courtdate: nil,
          days_since_last_payment: nil,
          eviction_date: nil,
          is_paused_until: nil,
          last_communication_action: nil,
          last_communication_date: nil,
          nosp: { served_date: nil },
          nosp_served: nil,
          nosp_served_date: nil,
          patch_code: nil,
          pause_comment: nil,
          pause_reason: nil,
          payment_ref: nil,
          uc_direct_payment_received: nil,
          uc_direct_payment_requested: nil,
          uc_rent_verification: nil,
          universal_credit: nil,
          weekly_rent: tenancy_1.weekly_rent.to_s,
          created_at: tenancy_1.created_at.iso8601(3),
          updated_at: tenancy_1.updated_at.iso8601(3)
        )
      )
    end

    # Currently tests when a tenancy has a NOSP after the new 3 month actionable period. Will have to change back to 28 days in future
    context 'when the tenancy has a NOSP' do
      let(:nosp_served_date) { 4.month.ago }
      let(:tenancy_1) { create(:case_priority, tenancy_ref: 1234, nosp_served_date: nosp_served_date) }

      it 'returns a tenancy' do
        expect_any_instance_of(Hackney::Income::GetTenancy).to receive(:execute).with(
          tenancy_ref: tenancy_1.tenancy_ref
        ).and_call_original

        get :show, params: { tenancy_ref: tenancy_1.tenancy_ref }

        expect(response.status).to eq(200)

        tenancy_hash = JSON.parse(response.body, symbolize_names: true)

        expect(tenancy_hash).to match(
          a_hash_including(
            id: tenancy_1.id,
            tenancy_ref: tenancy_1.tenancy_ref,
            nosp: {
              active: true,
              expires_date: (nosp_served_date + Hackney::Domain::Nosp::ACTIVE_TIME).strftime('%FT%T.000Z'),
              in_cool_off_period: false,
              served_date: nosp_served_date.strftime('%FT%T.000Z'),
              valid_until_date: (nosp_served_date + Hackney::Domain::Nosp::ACTIVE_TIME + 52.weeks).strftime('%FT%T.000Z'),
              valid: true
            },
            nosp_served_date: nosp_served_date.strftime('%FT%T.000Z'),
            # The follwoing attributes are stored on the Case Pirority Model
            active_nosp: nil,
            nosp_served: nil
          )
        )
      end
    end

    context 'when tenancy is not found' do
      it 'returns 404' do
        get :show, params: { tenancy_ref: 'not a tenancy ref' }

        expect(response.status).to eq(404)
      end
    end
  end

  context 'when receiving valid params' do
    it 'passes the correct params to the use case' do
      expect_any_instance_of(Hackney::Income::SetTenancyPausedStatus).to receive(:execute).with(
        username: paused_parms.fetch(:username),
        tenancy_ref: paused_parms.fetch(:tenancy_ref),
        until_date: paused_parms.fetch(:is_paused_until),
        pause_reason: paused_parms.fetch(:pause_reason),
        pause_comment: paused_parms.fetch(:pause_comment),
        action_code: paused_parms.fetch(:action_code)
      ).and_call_original

      patch :update, params: paused_parms

      expect(response.status).to eq(204)
    end

    it 'returns a 200 response' do
      expect_any_instance_of(Hackney::Income::SetTenancyPausedStatus).to receive(:execute).with(
        username: params2.fetch(:username),
        tenancy_ref: params2.fetch(:tenancy_ref),
        until_date: params2.fetch(:is_paused_until).to_s,
        pause_reason: params2.fetch(:pause_reason),
        pause_comment: params2.fetch(:pause_comment),
        action_code: params2.fetch(:action_code)
      ).and_call_original

      patch :update, params: params2

      expect(response.status).to eq(204)
    end
  end

  context 'when receiving valid params' do
    it 'passes the correct params to the use case' do
      expect_any_instance_of(Hackney::Income::GetTenancyPause).to receive(:execute).with(
        tenancy_ref: paused_parms.fetch(:tenancy_ref)
      ).and_call_original

      get :pause, params: { tenancy_ref: paused_parms.fetch(:tenancy_ref) }

      expect(response.status).to eq(200)
    end
  end

  context 'when receiving a request missing params' do
    it 'returns a 400 - bad request' do
      assert_incomplete_params(
        tenancy_ref: Faker::Lorem.characters(number: 8)
      )
    end
  end

  def assert_incomplete_params(params_hash)
    expect do
      patch :update, params: params_hash
    end.to raise_error ActionController::ParameterMissing
  end
end

class StubSqlPauseTenancyGateway
  def set_paused_until(tenancy_ref:, until_date:, pause_reason:, pause_comment:); end

  def get_tenancy_pause(tenancy_ref:); end

  def find(tenancy_ref:)
    {
      'id' => 91_945,
      'tenancy_ref' => '055593/01',
      'created_at' => '2019-04-02T03:26:35.000Z',
      'updated_at' => '2019-09-16T13:25:45.000Z',
      'balance' => '430.9',
      'days_in_arrears' => 1126,
      'days_since_last_payment' => 1227,
      'active_agreement' => false,
      'nosp_served' => false,
      'active_nosp' => false,
      'is_paused_until' => nil,
      'pause_reason' => nil,
      'pause_comment' => nil,
      'case_id' => 7250
    }
  end
end
