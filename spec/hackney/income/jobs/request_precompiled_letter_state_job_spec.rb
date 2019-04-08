require 'rails_helper'

RSpec.describe Hackney::Income::Jobs::RequestPrecompiledLetterStateJob, type: :job do
  let(:document) { create(:document) }

  describe '#perform' do
    it do
      expect_any_instance_of(Hackney::Notification::RequestPrecompiledLetterState).to receive(:execute).with(message_id: document.ext_message_id)
      described_class.perform_now(document_id: document.id)
    end
  end
end
