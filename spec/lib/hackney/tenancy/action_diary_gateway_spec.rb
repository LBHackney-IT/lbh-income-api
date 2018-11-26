require 'rails_helper'

describe Hackney::Tenancy::ActionDiaryGateway do
  let(:host) { Faker::Internet.url('example.com') }
  let(:key) { SecureRandom.uuid }
  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:action_balance) { Faker::Commerce.price }
  let(:username) { Faker::Name.name }
  let(:action_code) { Faker::Internet.slug }
  let(:comment) { Faker::Lorem.paragraph }

  API_HEADER_NAME = 'x-api-key'.freeze

  subject { described_class.new(host: host, api_key: key) }

  context 'when creating an action diary entry' do
    before do
      stub_request(:post, /#{host}/).with(headers: { API_HEADER_NAME => key }).to_return(status: 200)
    end

    it 'shoud create an system entry' do
      subject.create_entry(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        action_balance: action_balance,
        comment: comment
      )

      assert_requested(
        :post, host + '/tenancies/arrears-action-diary',
        headers: { API_HEADER_NAME => key },
        body: {
          tenancyAgreementRef: tenancy_ref,
          actionCode: action_code,
          actionBalance: action_balance,
          comment: comment
        }.to_json,
        times: 1
      )
    end

    it 'shoud create a entry with user user if username supplyed' do
      subject.create_entry(tenancy_ref: tenancy_ref,
                           action_code: action_code,
                           action_balance: action_balance,
                           comment: comment,
                           username: username)

      assert_requested(
        :post, host + '/tenancies/arrears-action-diary',
        headers: { API_HEADER_NAME => key },
        body: {
          tenancyAgreementRef: tenancy_ref,
          actionCode: action_code,
          actionBalance: action_balance,
          comment: comment,
          username: username
        }.to_json,
        times: 1
      )
    end
  end

  context 'when tenancy api returns an error' do
    before do
      stub_request(:post, /#{host}/).with(headers: { API_HEADER_NAME => key }).to_return(status: 500)
    end

    it 'an exception should be thrown' do
      expect {
        subject.create_entry(
          tenancy_ref: tenancy_ref,
          action_code: action_code,
          action_balance: action_balance,
          comment: comment,
          username: username
        )
      }.to raise_error(Hackney::Tenancy::TenancyApiException)
    end
  end
end
