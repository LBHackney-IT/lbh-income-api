require 'rails_helper'

describe Hackney::Income::ProcessLetter do
  let(:cloud_storage) { instance_double(Hackney::Cloud::Storage) }

  let(:subject) { described_class.new(cloud_storage: cloud_storage) }
  let(:username) { Faker::Name.name }
  let(:email) { Faker::Internet.email }
  let(:html) { "<h1>#{Faker::RickAndMorty.quote}</h1>" }
  let(:uuid) { SecureRandom.uuid }

  let(:pdf_file) { File.open('spec/test_files/test_pdf.pdf', 'rb') }

  let(:cache_obj) do
    {
      case: {
        payment_ref: 12_342_123,
        lessee_full_name: 'Mr Philip Banks',
        correspondence_address1: '508 Saint Cloud Road',
        correspondence_address2: 'Southwalk',
        correspondence_address3: 'London',
        correspondence_postcode: 'SE1 0SW',
        lessee_short_name: 'Philip',
        property_address: '1 Hillman St, London, E8 1DY',
        arrears_letter_1_date: '20th Feb 2019',
        total_collectable_arrears_balance: '3506.90'
      },
      uuid: uuid,
      preview: html,
      template: { template_id: Faker::Number.number }
    }
  end

  before do
    Rails.cache.write(uuid, cache_obj)
    allow(File).to receive(:delete)
  end

  it 'calls storage.save' do
    expect(cloud_storage).to receive(:save).with(
      uuid: uuid,
      letter_html: html,
      filename: "#{uuid}.pdf",
      metadata: {
        username: username,
        email: email,
        payment_ref: cache_obj[:case][:payment_ref],
        template: cache_obj[:template]
      }
    )

    subject.execute(uuid: uuid, username: username, email: email)
  end
end
