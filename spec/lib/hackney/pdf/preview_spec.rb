require 'rails_helper'

describe Hackney::PDF::Preview do
  subject do
    described_class.new(
      get_templates_gateway: get_templates_gateway,
      leasehold_information_gateway: leasehold_information_gateway,
      users_gateway: users_gateway
    )
  end

  let(:get_templates_gateway) { instance_double(Hackney::PDF::GetTemplates) }
  let(:leasehold_information_gateway) { instance_double(Hackney::Income::UniversalHousingLeaseholdGateway) }
  let(:users_gateway) { Hackney::Income::SqlUsersGateway.new }
  let(:test_user) do
    Hackney::Income::Models::User.create(
      provider_uid: 'close-to-me',
      provider: 'universal',
      name: 'Robert Smith',
      email: 'old-email@the-cure.com',
      first_name: 'Robert',
      last_name: 'Smith',
      provider_permissions: '12345.98765'
    )
  end
  let(:test_template_id) { 123_123 }
  let(:test_template) do
    {
      path: 'spec/lib/hackney/pdf/test_template.erb',
      id: test_template_id
    }
  end
  let(:test_pay_ref) { 1_234_567_890 }
  let(:test_letter_params) do
    {
      payment_ref: test_pay_ref,
      lessee_full_name: 'Mr Philip Banks',
      lessee_short_name: 'Philip',
      correspondence_address1: '508 Saint Cloud Road',
      correspondence_address2: 'Southwalk',
      correspondence_address3: 'London',
      correspondence_address4: 'London',
      correspondence_address5: 'England',
      correspondence_postcode: 'SE1 0SW',
      property_address: '1 Hillman St, London, E8 1DY',
      arrears_letter_1_date: '20th Feb 2019',
      total_collectable_arrears_balance: '3506.90'
    }
  end

  let(:translated_html) { File.open('spec/lib/hackney/pdf/translated_test_template.html').read }

  it 'generates letter preview' do
    expect(leasehold_information_gateway).to receive(:get_leasehold_info).with(payment_ref: test_pay_ref).and_return(test_letter_params)
    expect(get_templates_gateway).to receive(:execute).and_return([test_template])

    preview = subject.execute(payment_ref: test_pay_ref, template_id: test_template_id, user_id: test_user.id)

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
        payment_ref: test_pay_ref,
        lessee_full_name: 'P Banks',
        correspondence_address1: '',
        correspondence_address2: '',
        correspondence_address3: '',
        correspondence_postcode: '',
        lessee_short_name: '',
        property_address: '1 Hillman St, London, E8 1DY',
        arrears_letter_1_date: '20th Feb 2019',
        total_collectable_arrears_balance: '3506.90'
      }
    end

    let(:translated_html) { File.open('spec/lib/hackney/pdf/translated_test_template_with_blanks.html').read }

    it 'generates letter preview with errors' do
      expect(leasehold_information_gateway).to receive(:get_leasehold_info).with(payment_ref: test_pay_ref).and_return(test_letter_params)
      expect(get_templates_gateway).to receive(:execute).and_return([test_template])

      preview = subject.execute(payment_ref: test_pay_ref, template_id: test_template_id, user_id: test_user.id)

      expect(preview).to include(
        case: test_letter_params,
        template: test_template,
        preview: translated_html,
        errors: [
          {
            name: 'correspondence_address1',
            message: 'missing mandatory field'
          }, {
            name: 'correspondence_address2',
            message: 'missing mandatory field'
          }, {
            name: 'correspondence_postcode',
            message: 'missing mandatory field'
          }
        ]
      )
    end
  end
end
