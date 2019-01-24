require 'rails_helper'

describe Hackney::Tenancy::Gateway::ContactsGateway do
  let(:hostname) { Faker::Internet.url('example.com') }
  let(:api_key) { SecureRandom.uuid }
  let(:gateway) { described_class.new(host: hostname, api_key: api_key) }

  let(:example_return) { generate_example_return }

  context 'when retrieving a tenancy with contacts' do
    subject { gateway.get_responsible_contacts(tenancy_ref: tenancy_ref) }

    let(:tenancy_ref) { '123456/09' }
    let(:tenancy_ref_url_encoded) { '123456%2F09' }

    before do
      stub_request(:get, hostname + "/api/v1/tenancies/#{tenancy_ref_url_encoded}/contacts")
        .with(headers: { 'x-api-key' => api_key })
        .to_return(body: example_return.to_json)
    end

    it 'makes a get request data from the tenancy api' do
      subject
      expect(WebMock).to have_requested(:get, hostname + "/api/v1/tenancies/#{tenancy_ref_url_encoded}/contacts").once
    end

    it 'returns an array of Hackney::Income::domain::Contact objects' do
      expect(subject).to all(be_an(Hackney::Income::Domain::Contact))
    end

    it 'returns an array of available phone numbers' do
      expect(subject.first.phone_numbers).to eq(
        [
          example_return[:data][:contacts].first[:telephone1],
          example_return[:data][:contacts].first[:telephone2],
          example_return[:data][:contacts].first[:telephone3]
        ]
      )
      expect(WebMock).to have_requested(:get, hostname + "/api/v1/tenancies/#{tenancy_ref_url_encoded}/contacts").once
    end

    it 'returns an email' do
      expect(subject.first.email).to eq(example_return[:data][:contacts].first[:email])
      expect(WebMock).to have_requested(:get, hostname + "/api/v1/tenancies/#{tenancy_ref_url_encoded}/contacts").once
    end
  end

  context 'when retrieving a tenancy without any contacts' do
    subject { gateway.get_responsible_contacts(tenancy_ref: tenancy_ref) }

    let(:tenancy_ref) { '123456/09' }
    let(:tenancy_ref_url_encoded) { '123456%2F09' }

    let(:example_return) do
      {
        "data": {
          "contacts": []
        }
      }
    end

    before do
      stub_request(:get, hostname + "/api/v1/tenancies/#{tenancy_ref_url_encoded}/contacts")
        .with(headers: { 'x-api-key' => api_key })
        .to_return(body: example_return.to_json)
    end

    it 'returns an empty array' do
      expect(subject).to eq([])
      expect(WebMock).to have_requested(:get, hostname + "/api/v1/tenancies/#{tenancy_ref_url_encoded}/contacts").once
    end
  end

  context 'when retrieving a tenancy causes a timeout' do
    subject { gateway.get_responsible_contacts(tenancy_ref: tenancy_ref) }

    let(:tenancy_ref) { '123456/09' }
    let(:tenancy_ref_url_encoded) { '123456%2F09' }

    before do
      stub_request(:get, hostname + "/api/v1/tenancies/#{tenancy_ref_url_encoded}/contacts")
        .with(headers: { 'x-api-key' => api_key })
        .to_return(status: 504)
    end

    it 'raises a TenancyApiException' do
      expect { subject }.to raise_error Hackney::Tenancy::Exceptions::TenancyApiException

      expect(WebMock).to have_requested(:get, hostname + "/api/v1/tenancies/#{tenancy_ref_url_encoded}/contacts").once
    end
  end

  def generate_example_return
    # note there are more fields returned than this
    {
      "data": {
        "contacts": [
          {
            "responsible": true,
            "contact_id": SecureRandom.uuid,
            "email_address": Faker::Internet.safe_email,
            "address_line1": Faker::Address.street_name,
            "address_line2": Faker::Address.secondary_address,
            "address_line3": Faker::Address.community,
            "post_code": Faker::Address.postcode,
            "first_name": Faker::Name.first_name,
            "last_name": Faker::Name.last_name,
            "full_name": Faker::Name.name,
            "title": Faker::Name.prefix,
            "age": Faker::Number.number(2),
            "telephone1": Faker::PhoneNumber.phone_number,
            "telephone2": Faker::PhoneNumber.phone_number,
            "telephone3": Faker::PhoneNumber.phone_number
          },
          {
            "responsible": true,
            "contact_id": SecureRandom.uuid,
            "email_address": Faker::Internet.safe_email,
            "address_line1": Faker::Address.street_name,
            "address_line2": Faker::Address.secondary_address,
            "address_line3": Faker::Address.community,
            "post_code": Faker::Address.postcode,
            "first_name": Faker::Name.first_name,
            "last_name": Faker::Name.last_name,
            "full_name": Faker::Name.name,
            "title": Faker::Name.prefix,
            "age": Faker::Number.number(2),
            "telephone1": Faker::PhoneNumber.phone_number,
            "telephone2": Faker::PhoneNumber.phone_number,
            "telephone3": Faker::PhoneNumber.phone_number
          },
          {
            "responsible": false,
            "contact_id": SecureRandom.uuid,
            "email_address": Faker::Internet.safe_email,
            "address_line1": Faker::Address.street_name,
            "address_line2": Faker::Address.secondary_address,
            "address_line3": Faker::Address.community,
            "post_code": Faker::Address.postcode,
            "first_name": Faker::Name.first_name,
            "last_name": Faker::Name.last_name,
            "full_name": Faker::Name.name,
            "title": Faker::Name.prefix,
            "age": Faker::Number.number(2),
            "telephone1": Faker::PhoneNumber.phone_number,
            "telephone2": Faker::PhoneNumber.phone_number,
            "telephone3": Faker::PhoneNumber.phone_number
          }
        ]
      },
      "statusCode": 200,
      "error": nil
    }
  end
end
