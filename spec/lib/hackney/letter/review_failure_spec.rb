require 'rails_helper'

describe Hackney::Letter::ReviewFailure do
  describe '#execute' do
    subject(:review_failure) { described_class.new(cloud_storage: storage) }

    let(:cloud_adapter_fake) { double(:upload) }
    let(:storage) { Hackney::Cloud::Storage.new(cloud_adapter_fake, Hackney::Cloud::Document) }

    let(:id) { Random.rand(100) }

    let(:document) { create(:document, id: id) }

    it 'status is updated to failure_reviewed' do
      expect(storage).to receive(:update_document_status).with(document: document, status: :failure_reviewed).and_call_original

      expect { review_failure.execute(document_id: id) }
        .to change { document.reload.status }.from('uploaded').to('failure_reviewed')
    end
  end
end
