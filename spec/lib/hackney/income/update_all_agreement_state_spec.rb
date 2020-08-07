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
      3.times { create_agreement(:live) }
      2.times { create_agreement(:breached) }
    end

    it 'calls update agreement status 5 times' do
      expect(update_agreement_state).to receive(:execute).exactly(5).times

      subject
    end
  end

  def create_agreement(state)
    tenancy_ref = Faker::Lorem.characters(number: 8)
    create(:case_priority, tenancy_ref: tenancy_ref)
    agreement = create(:agreement,
                       tenancy_ref: tenancy_ref,
                       start_date: Date.today - 10.days,
                       frequency: :weekly)
    create(:agreement_state, state, agreement: agreement)
    agreement
  end
end
