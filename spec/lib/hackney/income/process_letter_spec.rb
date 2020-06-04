require 'rails_helper'

describe Hackney::Income::ProcessLetter do
  subject { described_class.new(cloud_storage: cloud_storage_spy) }

  let(:cloud_storage_spy) { spy }
  let(:username) { Faker::Name.name }
  let(:email) { Faker::Internet.email }
  let(:html) { "<h1>#{Faker::TvShows::RickAndMorty.quote}</h1>" }
  let(:uuid) { SecureRandom.uuid }
  let(:payment_ref) { Faker::Number.number(digits: 6) }
  let(:template_name) { Faker::Lorem.word }

  it 'calls storage.save' do
    expect(cloud_storage_spy).to receive(:save).with(
      uuid: uuid,
      letter_html: html,
      filename: "#{uuid}.pdf",
      metadata: {
        username: username,
        email: email,
        payment_ref: payment_ref,
        template: template_name
      }
    )

    subject.execute(
      uuid: uuid, username: username, email: email, payment_ref: payment_ref,
      template_name: template_name, letter_content: html
    )
  end
end
