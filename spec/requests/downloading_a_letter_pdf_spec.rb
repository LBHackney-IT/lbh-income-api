require 'rails_helper'

RSpec.describe 'Downloading a PDF', type: :request do
  include MockAwsHelper

  let(:real_template_id) { 'letter_before_action' }
  let(:payment_ref) { Faker::Number.number(6) }
  let(:house_ref) { Faker::Number.number(6) }
  let(:prop_ref) { Faker::Number.number(6) }
  let(:tenancy_ref) { Faker::Number.number(6) }
  let(:postcode) { Faker::Address.postcode }
  let(:letter_json) { [] }
  let(:user_group) { 'leasehold-group' }
  let(:user) {
    {
      id: 1,
      name: Faker::Name.name,
      email: Faker::Internet.email,
      groups: [user_group]
    }
  }

  before do
    Timecop.freeze
    mock_aws_client
    create_valid_uh_records_for_a_letter

    stub_request(:post, 'http://example.com/api/v2/tenancies/arrears-action-diary')
  end

  after { Timecop.return }

  context 'when I call preview then documents' do
    before do
      post messages_letters_path, params: {
        payment_ref: payment_ref,
        template_id: real_template_id,
        user: user
      }

      letter_json << JSON.parse(response.body)
      get "/api/v1/documents/#{letter_json[0]['document_id']}/download#{query_string}"
    end

    context 'with a username' do
      let(:query_string) { "?username=#{user[:name]}" }

      it 'responds with a PDF' do
        expect(response.headers['Content-Type']).to eq('application/pdf')
      end

      it 'asks the tenancy API to record an action' do
        expect(a_request(
          :post, 'http://example.com/api/v2/tenancies/arrears-action-diary'
        )
            .with(body: {
              tenancyAgreementRef: tenancy_ref,
              actionCode: 'SLB',
              actionCategory: '9',
              comment: 'LBA sent (SC)',
              username: user[:name],
              createdDate: DateTime.now.iso8601
            })).to have_been_made.once
      end

      it 'updates the status to downloaded' do
        get 'http://example.com/api/v1/documents'
        expect(response).to be_successful
        response_payment_reference = JSON.parse(JSON.parse(response.body)['documents'][0]['metadata'])['payment_ref']
        status = JSON.parse(response.body)['documents'][0]['status']
        expect(response_payment_reference).to eq(payment_ref)
        expect(status).to eq('downloaded')
      end

      context 'when you download a second time' do
        before do
          get "/api/v1/documents/#{letter_json[0]['document_id']}/download#{query_string}"
        end

        it 'responds with a PDF' do
          expect(response.headers['Content-Type']).to eq('application/pdf')
        end

        it 'does not write to the action diary twice' do
          expect(a_request(
                   :post, 'http://example.com/api/v2/tenancies/arrears-action-diary'
                 )).to have_been_made.once
        end
      end

      context 'when downloading from the documents list view' do
        let(:query_string) { "?username=#{user[:name]}&documents_view=true" }

        it 'does not write to the action diary if it is being downloaded from the view' do
          expect(a_request(
            :post, 'http://example.com/api/v2/tenancies/arrears-action-diary'
          )
              .with(body: {
                tenancyAgreementRef: tenancy_ref,
                actionCode: 'SLB',
                actionCategory: '9',
                comment: 'LBA sent (SC)',
                username: user[:name],
                createdDate: DateTime.now.iso8601
              })).not_to have_been_made
        end
      end
    end

    context 'without a username' do
      let(:user) {
        {
          name: nil,
          groups: [user_group]

        }
      }
      let(:query_string) { "?username=#{user[:name]}" }

      it 'responds with a PDF' do
        expect(response.headers['Content-Type']).to eq('application/pdf')
      end

      it 'does not ask the tenancy API to record an action' do
        expect(a_request(
                 :post, 'http://example.com/api/v2/tenancies/arrears-action-diary'
               )).not_to have_been_made
      end
    end
  end

  context 'when a letter is status is not uploaded' do
    let(:query_string) { "?username=#{user[:name]}" }

    before do
      post messages_letters_path, params: {
        payment_ref: payment_ref,
        template_id: real_template_id,
        user: user
      }
    end

    it 'responds with a PDF when I call preview then documents' do
      letter_json = JSON.parse(response.body)

      document = Hackney::Cloud::Document.find(letter_json['document_id'])
      document.update(status: 'received')

      get "/api/v1/documents/#{letter_json['document_id']}/download#{query_string}"
    end

    it 'does not write to the action diary when it has been downloaded' do
      expect(a_request(
        :post, 'http://example.com/api/v2/tenancies/arrears-action-diary'
      )
          .with(body: {
            tenancyAgreementRef: tenancy_ref,
            actionCode: 'SLB',
            actionCategory: '9',
            comment: 'LBA sent (SC)',
            username: user[:name],
            createdDate: DateTime.now.iso8601
          })).not_to have_been_made
    end
  end

  def create_valid_uh_records_for_a_letter
    create_uh_property(
      property_ref: prop_ref,
      post_code: postcode
    )
    create_uh_tenancy_agreement(
      prop_ref: prop_ref,
      tenancy_ref: tenancy_ref,
      u_saff_rentacc: payment_ref,
      house_ref: house_ref
    )
    create_uh_househ(
      house_ref: house_ref,
      prop_ref: prop_ref,
      corr_preamble: 'address1',
      corr_desig: 'address2',
      corr_postcode: postcode,
      house_desc: 'Test Name'
    )
    create_uh_rent(
      prop_ref: prop_ref,
      sc_leasedate: ''
    )
    create_uh_postcode(
      post_code: postcode,
      aline1: ''
    )
  end
end
