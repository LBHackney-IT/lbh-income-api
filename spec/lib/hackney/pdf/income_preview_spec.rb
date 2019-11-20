require 'rails_helper'

describe Hackney::PDF::IncomePreview do
  subject do
    described_class.new(
      get_templates_gateway: get_templates_gateway,
      income_information_gateway: income_information_gateway
    )
  end

  let(:get_templates_gateway) { instance_double(Hackney::PDF::GetTemplates) }
  let(:income_information_gateway) { instance_double(Hackney::Income::UniversalHousingIncomeGateway) }
  let(:username) { Faker::Name.name }
  let(:test_template_id) { 123_123 }
  let(:test_template) do
    {
      path: 'spec/lib/hackney/pdf/test_income_template.erb',
      id: test_template_id
    }
  end
  let(:test_tenancy_ref) { 1_234_567_890 }
  let(:test_payment_ref) { 1_234_567_890 }
  let(:test_property_ref) { 1_234_567_890 }
  let(:test_letter_params) do
    {
      tenancy_ref: test_tenancy_ref,
      payment_ref: test_payment_ref,
      property_ref: test_property_ref,
      address_line1: '508 Saint Cloud Road',
      address_line2: 'Southwalk',
      address_line3: 'London',
      address_line4: 'London',
      address_name_number: '',
      address_post_code: 'SE1 0SW',
      address_preamble: '',
      title: '',
      forename: 'Bloggs',
      surname: 'Joe',
      total_collectable_arrears_balance: '3506.90'
    }
  end

  let(:translated_html) { File.open('spec/lib/hackney/pdf/translated_test_income_template.html').read }

  it 'generates letter preview' do
    expect(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
    expect(get_templates_gateway).to receive(:execute).and_return([test_template])

    preview = subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, username: username)

    expect(preview).to include(
      case: test_letter_params,
      template: test_template,
      preview: translated_html,
      errors: []
    )
  end

  context 'when there\'s missing data' do
    let(:test_letter_params) do
      {
        tenancy_ref: test_tenancy_ref,
        payment_ref: test_payment_ref,
        property_ref: test_property_ref,
        address_line1: '508 Saint Cloud Road',
        address_line2: '',
        address_line3: '',
        address_line4: '',
        address_name_number: '',
        address_post_code: '',
        address_preamble: '',
        title: '',
        forename: '',
        surname: '',
        total_collectable_arrears_balance: '3506.90'
      }
    end

    let(:translated_html) { File.open('spec/lib/hackney/pdf/translated_test_income_template_with_blanks.html').read }

    it 'generates letter preview with errors' do
      expect(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
      expect(get_templates_gateway).to receive(:execute).and_return([test_template])

      preview = subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, username: username)

      expect(preview).to include(
        case: test_letter_params,
        template: test_template,
        preview: translated_html,
        errors: [
          {
            name: 'forename',
            message: 'missing mandatory field'
          },
          {
            name: 'surname',
            message: 'missing mandatory field'
          },
          {
            name: 'address_line2',
            message: 'missing mandatory field'
          },
          {
            name: 'address_post_code',
            message: 'missing mandatory field'
          }
        ]
      )
    end
  end
end
