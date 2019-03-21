require 'rails_helper'

describe Hackney::Income::ProcessLetter do
  let(:pdf_generator) { instance_double(Hackney::PDF::Generator) }
  let(:cloud_storage) { instance_double(Hackney::Cloud::Storage) }

  let(:subject) { described_class.new(pdf_generator: pdf_generator, cloud_storage: cloud_storage) }
  let(:user_id) { Faker::Number.number }
  let(:html) { "<h1>#{Faker::RickAndMorty.quote}</h1>" }
  let(:uuid) { SecureRandom.uuid }

  let(:pdf_file) { File.open('spec/test_files/test_pdf.pdf', 'rb') }

  let(:cache_obj) do
    {
      case: {
        payment_ref: 12_342_123,
        lessee_full_name: 'Mr Philip Banks',
        correspondence_address_1: '508 Saint Cloud Road',
        correspondence_address_2: 'Southwalk',
        correspondence_address_3: 'London',
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
    expect(pdf_generator).to receive(:execute).with(html).and_return(FakePDFKit.new(pdf_file))

    expect(cloud_storage).to receive(:save).with(
      file: pdf_file,
      uuid: uuid,
      metadata: {
        user_id: user_id,
        payment_ref: cache_obj[:case][:payment_ref],
        template: cache_obj[:template]
      }
    )

    subject.execute(uuid: uuid, user_id: user_id)
  end

  it 'creates pdf' do
    allow(cloud_storage).to receive(:save)
    expect(pdf_generator).to receive(:execute).with(html).and_return(FakePDFKit.new(pdf_file))

    subject.execute(uuid: uuid, user_id: user_id)
  end
end

class FakePDFKit
  def initialize(return_file)
    @return_file = return_file
  end

  def to_file(html)
    @return_file
  end
end
