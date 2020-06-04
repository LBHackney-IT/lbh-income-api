require 'rails_helper'

describe UseCases::AutomateSendingLetters do
  include MockAwsHelper

  let(:automate_sending_letters) {
    described_class.new(
      case_ready_for_automation: case_ready_for_automation,
      case_classification_to_letter_type_map: case_classification_to_letter_type_map,
      generate_and_store_letter: generate_and_store_letter,
      send_letter_to_gov_notify: send_letter_to_gov_notify,
      set_tenancy_paused_status: set_tenancy_paused_status
    )
  }

  let(:case_ready_for_automation) { spy }
  let(:case_classification_to_letter_type_map) { spy }
  let(:generate_and_store_letter) { spy }
  let(:send_letter_to_gov_notify) { spy }
  let(:set_tenancy_paused_status) { spy }

  let(:case_priority) {
    build(:case_priority,
          tenancy_ref: Faker::Number.number(digits: 4),
          classification: :send_letter_one,
          patch_code: Faker::Number.number(digits: 4))
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

    context 'when generate_and_store_letter returns errors' do
      let(:validation_errors) {
        {
          errors: [
            { name: 'forename', message: 'missing mandatory field' },
            { name: 'surname', message: 'missing mandatory field' },
            { name: 'address_line2', message: 'missing mandatory field' },
            { name: 'address_post_code', message: 'missing mandatory field' }
          ]
        }
      }

      before do
        expect(generate_and_store_letter)
          .to receive(:execute)
          .and_return(validation_errors)
      end

      it 'does not send a letter' do
        expect(send_letter_to_gov_notify)
          .not_to receive(:perform_later)

        automate_sending_letters.execute(case_priority: case_priority)
      end

      it 'writes to the action diary' do
        expect(set_tenancy_paused_status).to receive(:execute)
          .with(
            username: 'MANAGE ARREARS SYSTEM',
            tenancy_ref: case_priority.tenancy_ref,
            until_date: 1.week.from_now.iso8601,
            action_code: 'RMD',
            pause_reason: 'Missing Data',
            pause_comment: 'Errors when generating Letter income_collection_letter_1: ' \
              "'forename: missing mandatory field; surname: missing mandatory field; " \
              "address_line2: missing mandatory field; address_post_code: missing mandatory field'"
          )

        automate_sending_letters.execute(case_priority: case_priority)
      end
    end
  end

  context 'when the checking the classification of a case' do
    let(:case_classification_to_letter_type_map) { UseCases::CaseClassificationToLetterTypeMap.new }
    let(:classification) { :not_valid_classification }

    let(:case_priority) {
      build(:case_priority,
            tenancy_ref: Faker::Number.number(digits: 4),
            classification: classification,
            patch_code: Faker::Number.number(digits: 4))
    }

    before do
      expect(automate_sending_letters).to receive(:enviornment_allow_to_send_automated_letters?).and_return(true)

      allow(case_classification_to_letter_type_map).to receive(:env_allowed_to_send_letter_one?).and_return(true)
      allow(case_classification_to_letter_type_map).to receive(:env_allowed_to_send_letter_two?).and_return(true)
    end

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
