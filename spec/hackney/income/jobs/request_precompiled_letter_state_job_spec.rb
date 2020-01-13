require 'rails_helper'

RSpec.describe Hackney::Income::Jobs::RequestPrecompiledLetterStateJob, type: :job do
  let(:document) { create(:document) }

  describe '#perform' do
    it do
      expect_any_instance_of(Hackney::Notification::RequestPrecompiledLetterState).to receive(:execute).with(document: document)
      described_class.perform_now(document_id: document.id)
    end
  end
end
