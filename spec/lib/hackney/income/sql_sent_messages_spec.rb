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

  context 'save sent messages' do
    before {
      subject.add_message(
        tenancy_ref: tenancy_1.tenancy_ref,
        template_id: template_id,
        version: version,
        message_type: email_type,
        personalisation: personalisation
      )
    }

    it 'should create a new sent messahe' do
      expect(Hackney::Income::Models::SentMessage.first).to have_attributes(
        tenancy_ref: tenancy_1.tenancy_ref,
        template_id: template_id,
        version: version,
        message_type: email_type,
        personalisation: personalisation
      )
    end
  end
end
