require 'rails_helper'

describe Hackney::Notification::EnqueueRequestAllPrecompiledLetterStates do
  subject { described_class.new(enqueue_job: enqueue_job, document_store: document_store) }

  let(:enqueue_job) { Hackney::Income::Jobs::RequestPrecompiledLetterStateJob }
  let(:document_store) { Hackney::Cloud::Document }

  before do
    Timecop.freeze(Time.local(1999))
  end

  after do
    Timecop.return
  end

  describe '#execute' do
    let!(:document) { create(:document) }

    it do
      expect {
        subject.execute
      }.to(have_enqueued_job(enqueue_job).with(document_id: document.id))
    end
  end

  describe '#new' do
    context 'when no status set' do
      let(:document) { create(:document, status: nil) }

      it { expect(subject.documents).not_to include(document) }
    end

    context 'when older than 7 days' do
      let(:document) { create(:document, updated_at: (Time.now - 8.days)) }

      it { expect(subject.documents).not_to include(document) }
    end

    context 'when less than 7 days' do
      let(:document) { create(:document, updated_at: (Time.now - 6.days)) }

      it { expect(subject.documents).to include(document) }
    end

    context 'when uploading, uploaded, failed, received, accepted' do
      let!(:uploading) { create(:document, status: :uploading) }
      let!(:uploaded) { create(:document, status: :uploaded) }
      let!(:received) { create(:document, status: :received) }
      let!(:accepted) { create(:document, status: :accepted) }
      let!(:failed) { create(:document, status: 'validation-failed') }

      it { expect(subject.documents).to include(uploading) }
      it { expect(subject.documents).to include(uploaded) }
      it { expect(subject.documents).to include(accepted) }
      it { expect(subject.documents).not_to include(received) }
      it { expect(subject.documents).not_to include(failed) }

      it 'all statuses should be checked' do
        document_store.statuses.each do |status|
          expect(document_store.find_by!(status: status)).to be_a document_store
        end
      end
    end
  end
end
