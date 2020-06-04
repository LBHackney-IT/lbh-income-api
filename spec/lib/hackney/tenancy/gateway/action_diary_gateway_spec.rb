require 'rails_helper'

describe Hackney::Tenancy::Gateway::ActionDiaryGateway do
  subject(:gateway) { described_class.new(host: host, api_key: key) }

  let(:host) { Faker::Internet.url(host: 'example.com') }
  let(:key) { SecureRandom.uuid }
  let(:tenancy_ref) { Faker::Lorem.characters(number: 8) }
  let(:username) { Faker::Name.name }
  let(:action_code) { Faker::Internet.slug }
  let(:comment) { Faker::Lorem.paragraph }
  let(:date) { Faker::Time.backward }

  let(:required_headers) do
    {
      'X-Api-Key' => key,
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }
  end

  context 'when creating an action diary entry' do
    before do
      stub_request(:post, /#{host}/).with(headers: required_headers).to_return(status: 200)
    end

    it 'creates an system entry' do
      gateway.create_entry(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        date: date
      )

      assert_requested(
        :post, host + '/api/v2/tenancies/arrears-action-diary',
        headers: required_headers,
        body: {
          tenancyAgreementRef: tenancy_ref,
          actionCode: action_code,
          actionCategory: '9',
          comment: comment,
          createdDate: date
        },
        times: 1
      )
    end

    it 'creates a entry with user user if username supplied' do
      gateway.create_entry(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username,
        date: date
      )

      assert_requested(
        :post, host + '/api/v2/tenancies/arrears-action-diary',
        headers: required_headers,
        body: {
          tenancyAgreementRef: tenancy_ref,
          actionCode: action_code,
          actionCategory: '9',
          comment: comment,
          username: username,
          createdDate: date
        },
        times: 1
      )
    end

    it 'creates a entry with shortened user name if username supplied is longer than 40 chars' do
      gateway.create_entry(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: 'Hubert Wolfeschlegelsteinhausenbergerdorff',
        date: date
      )

      assert_requested(
        :post, host + '/api/v2/tenancies/arrears-action-diary',
        headers: required_headers,
        body: {
          tenancyAgreementRef: tenancy_ref,
          actionCode: action_code,
          actionCategory: '9',
          comment: comment,
          username: 'H. Wolfeschlegelsteinhausenbergerdorff',
          createdDate: date
        },
        times: 1
      )
    end
  end

  context 'when tenancy api returns an error' do
    before do
      stub_request(:post, /#{host}/).with(headers: required_headers).to_return(status: 500)
    end

    it 'an exception should be thrown' do
      expect {
        gateway.create_entry(
          tenancy_ref: tenancy_ref,
          action_code: action_code,
          comment: comment,
          date: date,
          username: username
        )
      }.to raise_error(
        Hackney::Tenancy::Exceptions::TenancyApiException
        # ,
        # "[Tenancy API error: Received 500 response] when trying to create action diary entry for #{tenancy_ref}"
      )
    end
  end
end
