require 'rails_helper'

describe Hackney::Income::SqlSentMessages do
  let(:tenancy_1) { create_tenancy_model }
  let(:template_id) { SecureRandom.uuid }
  let(:version) { Faker::Number.digit }
  let(:email_type) { Faker::Lorem.word }
  let(:personalisation) { { 'first name' => Faker::Lorem.word }.to_json }

  subject { described_class.new }

  before do
    tenancy_1.save
  end

  context 'sent messages' do
    before {
      subject.add_message(
        tenancy_ref: tenancy_1.tenancy_ref,
        template_id: template_id,
        version: version,
        message_type: email_type,
        personalisation: personalisation
      )
    }

    it 'should create a new sent message' do
      expect(Hackney::Income::Models::SentMessage.first).to have_attributes(
        tenancy_ref: tenancy_1.tenancy_ref,
        template_id: template_id,
        version: version,
        message_type: email_type,
        personalisation: personalisation
      )
    end

    it 'should retrieve all saved email given a tenancy ref' do
      expect(
        subject.get_sent_messages(
          tenancy_ref: tenancy_1.tenancy_ref,
          message_type: 'email'
        )
      ).to eq([Hackney::Income::Models::SentMessage.first])
    end
  end
end
