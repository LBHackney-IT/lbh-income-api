require 'rails_helper'

describe Hackney::Income::ProcessLetter do
  subject { described_class.new(cloud_storage: cloud_storage) }

  let(:cloud_storage) { instance_double(Hackney::Cloud::Storage) }
  let(:user_id) { Faker::Number.number }
  let(:html) { "<h1>#{Faker::RickAndMorty.quote}</h1>" }
  let(:uuid) { SecureRandom.uuid }
  let(:payment_ref) { Faker::Number.number(6) }
  let(:template_name) { Faker::Lorem.word }

  it 'calls storage.save' do
    expect(cloud_storage).to receive(:save).with(
      uuid: uuid,
      letter_html: html,
      filename: "#{uuid}.pdf",
      metadata: {
        user_id: user_id,
        payment_ref: payment_ref,
        template: template_name
      }
    )

    subject.execute(uuid: uuid, user_id: user_id, payment_ref: payment_ref, template_name: template_name,
                    letter_content: html)
  end
end
