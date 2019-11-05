require 'rails_helper'

RSpec.describe 'Downloading a PDF', type: :request do
  include MockAwsHelper

  let(:real_template_id) { 'letter_before_action' }
  let(:payment_ref) { Faker::Number.number(6) }
  let(:house_ref) { Faker::Number.number(6) }
  let(:prop_ref) { Faker::Number.number(6) }
  let(:postcode) { Faker::Address.postcode }
  let(:user_id) { create(:user).id }

  before do
    mock_aws_client
    create_valid_uh_records_for_a_letter
  end

  it 'responds with a PDF when I call preview then documents' do
    post messages_letters_path, params: {
      payment_ref: payment_ref, template_id: real_template_id, user_id: user_id
    }

    letter_json = JSON.parse(response.body)

    expect(letter_json['errors']).to eq([])
    expect(letter_json['document_id']).not_to be_nil

    get "/api/v1/documents/#{letter_json['document_id']}/download/"

    expect(response.headers['Content-Type']).to eq('application/pdf')
  end

  def create_valid_uh_records_for_a_letter
    create_uh_property(
      property_ref: prop_ref,
      post_code: postcode
    )
    create_uh_tenancy_agreement(
      prop_ref: prop_ref,
      tenancy_ref: Faker::Number.number(6),
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
