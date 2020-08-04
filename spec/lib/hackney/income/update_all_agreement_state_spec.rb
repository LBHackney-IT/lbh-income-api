require 'rails_helper'

describe Hackney::Income::UpdateAllAgreementState do
  subject { described_class.new(update_agreement_state: update_agreement_state).execute }

  let(:update_agreement_state) { double(Hackney::Income::UpdateAgreementState) }

  context 'when there are no active(live or breached) agreements' do
    before do
      create(:agreement_state, :cancelled)
      create(:agreement_state, :completed)
    end

    it 'does not run detect breach use case' do
      expect(update_agreement_state).not_to receive(:execute)

      subject
    end
  end

  context 'when there are 3 live, 2 breached, 1 completed and 1 cancelled agreements' do
    before do
      create_list(:agreement_state, 3, :live)
      create_list(:agreement_state, 2, :breached)
      create(:agreement_state, :completed)
      create(:agreement_state, :cancelled)
    end

    it 'calls update agreement status 5 times' do
      expect(update_agreement_state).to receive(:execute).exactly(5).times

      subject
    end
  end
end
