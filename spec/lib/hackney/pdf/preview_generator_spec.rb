require 'rails_helper'

describe Hackney::PDF::PreviewGenerator do
  subject do
    described_class.new(
      template_path: test_template_path
    )
  end

  before do
    stub_response_body = File.read('spec/lib/hackney/pdf/test_bank_holidays_api_response.txt')
    stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
      status: 200,
      body: stub_response_body
    )
  end

  let(:test_username) { 'Dave' }
  let(:test_template_path) { 'spec/lib/hackney/pdf/test_template.erb' }
  let(:test_letter_params) do
    {
      payment_ref: '1234567890',
      lessee_full_name: 'Mr Philip Banks',
      correspondence_address1: '508 Saint Cloud Road',
      correspondence_address2: 'Southwalk',
      correspondence_address3: 'London',
      correspondence_postcode: 'SE1 0SW',
      lessee_short_name: 'Philip',
      property_address: '1 Hillman St, London, E8 1DY',
      total_collectable_arrears_balance: '3506.90'
    }
  end

  let(:translated_html) { File.open('spec/lib/hackney/pdf/translated_test_template.html').read }

  it 'translates erb templates to html and shows no errors' do
    preview_with_errors = subject.execute(letter_params: test_letter_params, username: test_username)

    expect(preview_with_errors[:html]).to eq(translated_html)
    expect(preview_with_errors[:errors]).to eq([])
  end

  context 'when tomorrow is not a working day' do
    subject do
      described_class.new(
        template_path: test_working_days_path
      )
    end

    let(:test_working_days_path) { 'spec/lib/hackney/pdf/test_working_days_template.erb' }
    let(:translated_working_days_html) { File.open('spec/lib/hackney/pdf/translated_test_working_days_template.html').read }

    it 'sets the next working day as the sending date' do
      Timecop.freeze(2020, 05, 22)
      preview_with_errors = subject.execute(letter_params: test_letter_params, username: test_username)

      expect(preview_with_errors[:html]).to eq(translated_working_days_html)
      expect(preview_with_errors[:errors]).to eq([])

      Timecop.return
    end
  end

  context 'when data is missing' do
    let(:translated_html) { File.open('spec/lib/hackney/pdf/translated_test_template_with_blanks.html').read }

    let(:test_letter_params) do
      {
        payment_ref: '1234567890',
        lessee_full_name: 'P Banks',
        correspondence_address1: '',
        correspondence_address2: '',
        correspondence_address3: '',
        correspondence_postcode: '',
        lessee_short_name: '',
        property_address: '1 Hillman St, London, E8 1DY',
        total_collectable_arrears_balance: '3506.90',
        international: true
      }
    end

    it 'translates erb templates to html and shows errors' do
      preview_with_errors = subject.execute(letter_params: test_letter_params, username: test_username)

      expect(preview_with_errors[:html]).to eq(translated_html)
      expect(preview_with_errors[:errors]).to eq([
        {
          message: 'missing mandatory field', name: 'correspondence_address1'
        }, {
          message: 'missing mandatory field', name: 'correspondence_address2'
        }, {
          message: 'missing mandatory field', name: 'correspondence_postcode'
        }, {
          message: 'international address', name: 'address'
        }
      ])
    end
  end
end
