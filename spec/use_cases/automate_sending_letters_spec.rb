require 'rails_helper'

describe UseCases::AutomateSendingLetters do
  include MockAwsHelper

  let(:automate_sending_letters) {
    described_class.new(case_ready_for_automation: case_ready_for_automation,
                        check_case_classification_and_letter: check_case_classification_and_letter,
                        generate_and_store_letter: generate_and_store_letter,
                        send_income_collection_letter: send_income_collection_letter)
  }

  let(:case_ready_for_automation) { spy }
  let(:check_case_classification_and_letter) { spy }
  let(:generate_and_store_letter) { spy }
  let(:send_income_collection_letter) { spy }

  let(:case_priority) {
    {
      tenancy_ref: Faker::Number.number(4),
      classification: 'send_letter_1',
      patch_code: Faker::Number.number(4)
    }
  }

  let(:letter) { 'income_collection_letter_1' }

  context 'when the environment does not allow automation' do
    before do
      expect(automate_sending_letters).to receive(:enviornment_allow_to_send_automated_letters?).and_return(false)
    end

    it 'does not call `#automate_letters`' do
      expect(automate_sending_letters).not_to receive(:automate_letters)

      automate_sending_letters.execute(case_priority: case_priority)
    end

    it 'does not interact with the send_income_collection_letter job' do
      expect(send_income_collection_letter).not_to receive(:perform_later)

      automate_sending_letters.execute(case_priority: case_priority)
    end
  end

  context 'when the environment does allow automation' do
    before do
      expect(automate_sending_letters).to receive(:enviornment_allow_to_send_automated_letters?).and_return(true)
      expect(check_case_classification_and_letter).to receive(:execute).with(case_priority: case_priority).and_return(letter)
    end

    context 'when allowing a specific user to send letter 1 and 2' do
      before do
        mock_aws_client
      end

      let(:generate_and_store_letter) { UseCases::GenerateAndStoreLetter.new }

      it 'will allow an income collection user to generate and store letter 1 and 2' do
        automate_sending_letters.execute(case_priority: case_priority)
      end
    end

    it 'does call `#automate_letters`' do
      expect(automate_sending_letters).to receive(:automate_letters).with(case_priority: case_priority).and_call_original

      automate_sending_letters.execute(case_priority: case_priority)
    end

    it 'does interact with the #send_income_collection_letter job' do
      expect(send_income_collection_letter).to receive(:perform_later)

      automate_sending_letters.execute(case_priority: case_priority)
    end

    context 'when sending letter 1' do
      it 'will call the case_ready_for_automation and with the correct data' do
        automate_sending_letters.execute(case_priority: case_priority)
        allow(automate_sending_letters).to receive(:execute)

        expect(case_ready_for_automation).to have_received(:execute).with(patch_code: case_priority[:patch_code])
        expect(generate_and_store_letter).to have_received(:execute)
      end
    end

    context 'when sending a bogus letter' do
      let(:letter) { 'bogus_letter' }

      it 'does not call #generate_and_store_letter or #send_income_collection_letter' do
        expect(generate_and_store_letter).not_to receive(:execute)
        expect(send_income_collection_letter).not_to receive(:perform_later)

        automate_sending_letters.execute(case_priority: case_priority)
      end
    end
  end
end
