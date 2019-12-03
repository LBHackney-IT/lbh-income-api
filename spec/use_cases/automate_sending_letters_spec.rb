require 'rails_helper'

describe UseCases::AutomateSendingLetters do
  include MockAwsHelper

  let(:automate_sending_letters) {
    described_class.new(case_ready_for_automation: case_ready_for_automation,
                        case_classification_to_letter_type_map: case_classification_to_letter_type_map,
                        generate_and_store_letter: generate_and_store_letter,
                        send_letter_to_gov_notify: send_letter_to_gov_notify)
  }

  let(:case_ready_for_automation) { spy }
  let(:case_classification_to_letter_type_map) { spy }
  let(:generate_and_store_letter) { spy }
  let(:send_letter_to_gov_notify) { spy }

  let(:case_priority) {
    build(:case_priority,
          tenancy_ref: Faker::Number.number(4),
          classification: :send_letter_one,
          patch_code: Faker::Number.number(4))
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

    it 'does not interact with the send_letter_to_gov_notify job' do
      expect(send_letter_to_gov_notify).not_to receive(:perform_later)

      automate_sending_letters.execute(case_priority: case_priority)
    end
  end

  context 'when the environment does allow automation' do
    before do
      expect(automate_sending_letters).to receive(:enviornment_allow_to_send_automated_letters?).and_return(true)
      expect(case_classification_to_letter_type_map).to receive(:execute).with(case_priority: case_priority).and_return(letter)
    end

    context 'with a concrete implementation of #GenerateAndStoreLetter' do
      let(:generate_and_store_letter) { UseCases::GenerateAndStoreLetter.new }

      it 'with no valid tenancy ref, raises a tenancy not found error' do
        expect { automate_sending_letters.execute(case_priority: case_priority) }.to raise_error(Hackney::Income::TenancyNotFoundError)
      end
    end

    it 'does call `#automate_letters`' do
      expect(automate_sending_letters).to receive(:automate_letters).with(case_priority: case_priority).and_call_original

      automate_sending_letters.execute(case_priority: case_priority)
    end

    it 'does interact with the #send_letter_to_gov_notify job' do
      expect(send_letter_to_gov_notify).to receive(:perform_later)

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

      it 'does not call #generate_and_store_letter or #send_letter_to_gov_notify' do
        expect(generate_and_store_letter).not_to receive(:execute)
        expect(send_letter_to_gov_notify).not_to receive(:perform_later)

        automate_sending_letters.execute(case_priority: case_priority)
      end
    end
  end

  context 'when the checking the classification of a case' do
    before do
      expect(automate_sending_letters).to receive(:enviornment_allow_to_send_automated_letters?).and_return(true)
    end

    let(:case_classification_to_letter_type_map) { UseCases::CaseClassificationToLetterTypeMap.new }
    let(:classification) { :not_valid_classification }

    let(:case_priority) {
      build(:case_priority,
            tenancy_ref: Faker::Number.number(4),
            classification: classification,
            patch_code: Faker::Number.number(4))
    }

    context 'when the classification is not send_letter_one or send_letter_two' do
      let(:classification) { :send_letter_one }

      it 'will return nil' do
        expect(generate_and_store_letter).to receive(:execute).with(hash_including(template_id: 'income_collection_letter_1'))
        expect(send_letter_to_gov_notify).to receive(:perform_later)

        expect(automate_sending_letters.execute(case_priority: case_priority)).to eq(true)
      end
    end

    context 'when the classification is no_action' do
      let(:classification) { :no_action }

      it 'will return nil' do
        expect(generate_and_store_letter).not_to receive(:execute)
        expect(send_letter_to_gov_notify).not_to receive(:perform_later)

        expect(automate_sending_letters.execute(case_priority: case_priority)).to eq(false)
      end
    end
  end
end
