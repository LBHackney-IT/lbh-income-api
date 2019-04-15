require 'rails_helper'

describe Hackney::Notification::RequestPrecompiledLetterState do
  let!(:message_id) { SecureRandom.uuid }
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:add_action_diary_usecase) { double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:document_store) { Hackney::Cloud::Document }
  let(:notification_response) do
    described_class.new(
      notification_gateway: notification_gateway,
      add_action_diary_usecase: add_action_diary_usecase,
      document_store: document_store
    )
  end

  let(:document) do
    create(:document,
           filename: 'test_file.txt',
           ext_message_id: message_id,
           status: 'uploaded')
  end

  let(:response) { notification_response.execute(message_id: document.uuid) }

  describe '#execute' do
    it 'gets request' do
      expect(response[:status]).to eq 'received'
    end

    it 'updates document state' do
      doc = Hackney::Cloud::Document.find(document.id)
      expect(Raven).not_to receive(:send_event)
      expect { response }.to change { doc.reload.status }.from('uploaded').to('received')
    end
  end

  context 'when failure' do
    let(:doc) { Hackney::Cloud::Document.find(document.id) }

    before { expect(notification_gateway).to receive(:precompiled_letter_state).and_return(status: 'failed') }

    it 'change to failure raises Sentry notification' do
      expect { response }.to change { doc.reload.status }.from('uploaded').to('failed')
    end

    it 'raises Sentry notification' do
      expect(Raven).to receive(:send_event)
      response
    end
  end
end
