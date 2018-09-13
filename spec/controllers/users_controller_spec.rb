require 'rails_helper'

describe UsersController do
  let(:params) do
    {
      provider_uid: Faker::Lorem.characters(10),
      provider: Faker::Lorem.word,
      name: Faker::Name.name,
      email: Faker::Internet::email,
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      provider_permissions: Faker::Lorem.characters(4),
    }
  end

  context 'when receiving valid params' do
    it 'should pass the correct params to the use case' do
      expect_any_instance_of(Hackney::Income::FindOrCreateUser).to receive(:execute).with(
        provider_uid: params.fetch(:provider_uid),
        provider: params.fetch(:provider),
        name: params.fetch(:name),
        email: params.fetch(:email),
        first_name: params.fetch(:first_name),
        last_name: params.fetch(:last_name),
        provider_permissions: params.fetch(:provider_permissions)
      ).and_return(
        provider_uid: params.fetch(:provider_uid),
        provider: params.fetch(:provider),
        name: params.fetch(:name),
        email: params.fetch(:email),
        first_name: params.fetch(:first_name),
        last_name: params.fetch(:last_name),
        provider_permissions: params.fetch(:provider_permissions)
      )

      get :create, params: params
    end

    it 'should return the response as json' do
      get :create, params: params

      expect(response.body).to eq(
        {
          id: 1,
          name: params.fetch(:name),
          email: params.fetch(:email),
          first_name: params.fetch(:first_name),
          last_name: params.fetch(:last_name),
          provider_permissions: params.fetch(:provider_permissions)
        }.to_json
      )
    end
  end

  context 'when receiving a request missing params' do
    it 'should return a 400 - bad request' do
      assert_incomplete_params({
          provider_uid: Faker::Lorem.characters(10),
          provider: Faker::Lorem.word,
          name: Faker::Name.name,
          email: Faker::Internet::email,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
        })

      assert_incomplete_params({
          provider: Faker::Lorem.word,
          name: Faker::Name.name,
          email: Faker::Internet::email,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          provider_permissions: Faker::Lorem.characters(4)
        })

      assert_incomplete_params({
          provider_uid: Faker::Lorem.characters(10),
          name: Faker::Name.name,
          email: Faker::Internet::email,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          provider_permissions: Faker::Lorem.characters(4)
        })

      assert_incomplete_params({
          provider_uid: Faker::Lorem.characters(10),
          provider: Faker::Lorem.word,
          email: Faker::Internet::email,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          provider_permissions: Faker::Lorem.characters(4)
        })

      assert_incomplete_params({
          provider_uid: Faker::Lorem.characters(10),
          provider: Faker::Lorem.word,
          name: Faker::Name.name,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          provider_permissions: Faker::Lorem.characters(4)
        })

      assert_incomplete_params({
          provider_uid: Faker::Lorem.characters(10),
          provider: Faker::Lorem.word,
          name: Faker::Name.name,
          email: Faker::Internet::email,
          last_name: Faker::Name.last_name,
          provider_permissions: Faker::Lorem.characters(4)
        })

      assert_incomplete_params({
          provider_uid: Faker::Lorem.characters(10),
          provider: Faker::Lorem.word,
          name: Faker::Name.name,
          email: Faker::Internet::email,
          first_name: Faker::Name.first_name,
          provider_permissions: Faker::Lorem.characters(4)
        })
    end
  end

  def assert_incomplete_params(params_hash)
    expect {
      post :create, params: params_hash
    }.to raise_error ActionController::ParameterMissing
  end
end
