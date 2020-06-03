require 'rails_helper'
require_relative '../../../lib/sentry/sanatize_messages_processor'

describe SanatizeMessagesProcessor do
  let(:processor) { described_class.new }
  let(:data) { processor.process(sentry_data).dig(:extra, :params) }

  context 'when the processor is run' do
    it 'returns an expected hash' do
      expect(data[:message]).to have_key(:sanatized)
      expect(data[:variables]).to have_key(:sanatized)
      expect(data[:phone_number]).to eq Raven::Processor::STRING_MASK
      expect(data[:tenancy_ref]).to eq Raven::Processor::STRING_MASK
      expect(data[:phone_number]).to eq Raven::Processor::STRING_MASK
    end
  end

  def sentry_data
    {
      extra: {
        params: {
          action: 'send_email',
          controller: 'messages',
          email_address: Faker::Internet.email,
          message: {
            email_address: Faker::Internet.email,
            reference: Faker::Lorem.characters(number: 8),
            template_id: 'da658c4f-daa6-4691-8ec0-035837089fb5',
            tenancy_ref: Faker::Lorem.characters(number: 8),
            variables: {
              balance: 501.89,
              'first name' => 'Luz',
              'formal name' => 'Miss Littel',
              'full name' => 'Miss Luz Littel',
              'last name' => 'Littel',
              title: 'Miss'
            }
          },
          reference: "manual_#{Faker::Lorem.characters(number: 8)}",
          template_id: 'da658c4f-daa6-4691-8ec0-035837089fb5',
          tenancy_ref: Faker::Lorem.characters(number: 8),
          variables: {
            balance: 501.89,
            'first name' => 'Luz',
            'formal name' => 'Miss Littel',
            'full name' => 'Miss Luz Littel',
            'last name' => 'Littel',
            title: 'Miss'
          }
        }
      }
    }
  end
end
