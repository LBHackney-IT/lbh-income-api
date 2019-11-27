require 'rails_helper'

describe UseCases::FetchCasesAndSendLetterOne do
  let(:fetch_cases_and_send_letter_one) {
    described_class.new(case_ready_for_automation: case_ready_for_automation,
                        send_manual_precompiled_letter: send_manual_precompiled_letter)
  }

  let(:case_ready_for_automation) { spy }
  let(:send_manual_precompiled_letter) { spy }

  let(:case_priority) { 'a case' }
  let(:patch_code) { 'ABC' }

  context 'when sending letter 1' do
    it 'will call the case_ready_for_automation and with the correct data' do
      fetch_cases_and_send_letter_one.execute(
        case_priority: case_priority,
        patch_code: patch_code
      )
      allow(fetch_cases_and_send_letter_one).to receive(:execute)
      expect(case_ready_for_automation).to have_received(:execute).with(patch_code: patch_code, case_priority: case_priority)
    end
  end
end
