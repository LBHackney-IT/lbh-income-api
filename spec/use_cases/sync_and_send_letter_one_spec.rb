require 'rails_helper'

describe UseCases::SyncAndSendLetterOne do
  let(:sync_and_send_letter_one) {
    described_class.new(sync_case_priority: sync_case_priority,
                        fetch_cases_by_patch: fetch_cases_by_patch,
                        send_manual_precompiled_letter: send_manual_precompiled_letter)
  }

  let(:sync_case_priority) { spy }
  let(:fetch_cases_by_patch) { spy }
  let(:send_manual_precompiled_letter) { spy }

  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:username) { nil }
  let(:payment_ref) { nil }
  let(:template_id) { Faker::Lorem.characters(8) }
  let(:unique_reference) { Faker::Lorem.characters(8) }
  let(:letter_pdf) { '' }

  context 'when sending letter 1' do
    it 'will call the sync_case_priority, fetch_cases_by_patch and send_manual_precompiled_letter with the correct data' do
      sync_and_send_letter_one.execute(
        tenancy_ref: tenancy_ref,
        username: nil,
        payment_ref: nil,
        template_id: template_id,
        unique_reference: unique_reference,
        letter_pdf: letter_pdf
      )
      allow(sync_and_send_letter_one).to receive(:execute)

      expect(sync_case_priority).to have_received(:execute).with(tenancy_ref: tenancy_ref)
      expect(fetch_cases_by_patch).to have_received(:execute)
      expect(send_manual_precompiled_letter).to have_received(:execute)
        .with(
          username: nil,
          payment_ref: nil,
          template_id: template_id,
          unique_reference: unique_reference,
          letter_pdf: letter_pdf
        )
    end
  end
end
