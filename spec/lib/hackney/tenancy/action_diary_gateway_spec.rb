require 'rails_helper'

describe Hackney::Tenancy::ActionDiaryGateway do
  let(:host) { Faker::Internet.url('example.com') }
  let(:key) { SecureRandom.uuid }
  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:action_balance) { Faker::Commerce.price }
  let(:username) { Faker::Name.name }

  API_HEADER_NAME = 'x-api-key'.freeze

  subject { described_class.new(host: host, key: key) }

  context 'when creating an action diary entry' do
    before do
      stub_request(:post, /#{host}/).with(headers: { API_HEADER_NAME => key }).to_return(status: 200)
    end

    it 'shoud create an system entry' do
      subject.create_entry(
        tenancy_ref: tenancy_ref,
        action_code: '111',
        action_balance: action_balance,
        comment: 'bar'
      )

      assert_requested(
        :post, host + '/tenancies/arrears-action-diary',
        headers: { API_HEADER_NAME => key },
        body: {
          tenancyAgreementRef: tenancy_ref,
          actionCode: '111',
          actionBalance: action_balance,
          comment: 'bar'
        }.to_json,
        times: 1
      )
    end

    it 'shoud create a entry with user user if username supplyed' do
      subject.create_entry(tenancy_ref: tenancy_ref,
                           action_code: '111',
                           action_balance: action_balance,
                           comment: 'bar',
                           username: username)

      assert_requested(
        :post, host + '/tenancies/arrears-action-diary',
        headers: { API_HEADER_NAME => key },
        body: {
          tenancyAgreementRef: tenancy_ref,
          actionCode: '111',
          actionBalance: action_balance,
          comment: 'bar',
          username: username
        }.to_json,
        times: 1
      )
    end
  end
end
