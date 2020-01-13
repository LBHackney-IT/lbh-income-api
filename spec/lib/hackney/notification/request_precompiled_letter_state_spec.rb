require 'rails_helper'

describe Hackney::Notification::RequestPrecompiledLetterState do
  let!(:message_id) { SecureRandom.uuid }
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:add_action_diary_usecase) { double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:document_store) { Hackney::Cloud::Storage.new(double(:adapter), Hackney::Cloud::Document) }
  let(:case_priority_store) { double(Hackney::Income::Models::CasePriority) }

  let(:notification_response) do
    described_class.new(
      notification_gateway: notification_gateway,
      add_action_diary_usecase: add_action_diary_usecase,
      document_store: document_store,
      case_priority_store: case_priority_store
    )
  end

  let(:payment_ref) { Faker::Number.number(10) }

  let(:case_priority) { create(:case_priority, payment_ref: payment_ref) }

  let(:document) do
    create(:document,
           filename: 'test_file.txt',
           ext_message_id: message_id,
           status: 'uploaded')
  end

  let(:response) { notification_response.execute(document: document) }

  describe '#execute' do
    it 'gets request' do
      expect(response[:status]).to eq 'received'
    end

    it 'updates document state' do
      expect(Raven).not_to receive(:send_event)
      expect { response }.to change { document.reload.status }.from('uploaded').to('received')
    end
  end

  context 'when failure' do
    before { expect(notification_gateway).to receive(:precompiled_letter_state).and_return(status: 'validation-failed') }

    it 'raises Sentry notification' do
      expect(Raven).to receive(:send_event)
      expect { response }.to change { document.reload.status }.from('uploaded').to('validation-failed')
    end
  end

  context 'when an income collection letter fails validation' do
    let(:template_id) { Faker::Lorem.word }

    let(:document) do
      create(:document,
             metadata: {
               payment_ref: payment_ref,
               template: {
                 path: 'lib/hackney/pdf/templates/income/income_collection_letter_1.erb',
                 name: 'Income collection letter 1',
                 id: template_id
               }
             }.to_json)
    end

    it 'finds the relevant tenancy and writes into the action diary' do
      expect(notification_gateway).to receive(:precompiled_letter_state).and_return(status: 'validation-failed')

      expect(case_priority_store).to receive(:by_payment_ref).with(payment_ref).and_return(case_priority)

      expect(add_action_diary_usecase).to receive(:execute).with(
        tenancy_ref: case_priority.tenancy_ref,
        action_code: 'VFL',
        comment: "Letter '#{document.uuid}' from '#{template_id}' "\
                 'letter failed to send. Please check Gov Notify for more detail, once the issue is '\
                 "resolved update the document by visiting documents?payment_ref=#{payment_ref}"
      ).and_return(case_priority)

      expect { response }.to change { document.reload.status }.from('uploaded').to('validation-failed')
    end
  end
end
