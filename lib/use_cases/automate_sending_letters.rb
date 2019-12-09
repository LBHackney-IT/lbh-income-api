module UseCases
  class AutomateSendingLetters
    def initialize(case_ready_for_automation:, case_classification_to_letter_type_map:, generate_and_store_letter:, send_letter_to_gov_notify:)
      @case_ready_for_automation = case_ready_for_automation
      @case_classification_to_letter_type_map = case_classification_to_letter_type_map
      @generate_and_store_letter = generate_and_store_letter
      @send_letter_to_gov_notify = send_letter_to_gov_notify
    end

    def execute(case_priority:)
      automate_letters(case_priority: case_priority) if enviornment_allow_to_send_automated_letters?
    end

    private

    def automate_letters(case_priority:)
      return false unless @case_ready_for_automation.execute(patch_code: case_priority.patch_code)

      income_collection_letters = %w[income_collection_letter_1 income_collection_letter_2]

      letter_name = @case_classification_to_letter_type_map.execute(case_priority: case_priority)

      return false unless income_collection_letters.include?(letter_name)

      generate_letter = @generate_and_store_letter.execute(
        payment_ref: nil,
        tenancy_ref: case_priority.tenancy_ref,
        template_id: letter_name,
        user: generate_income_collection_user
      )
      @send_letter_to_gov_notify.perform_later(document_id: generate_letter[:document_id], tenancy_ref: case_priority.tenancy_ref)

      true
    end

    def enviornment_allow_to_send_automated_letters?
      ENV.fetch('CAN_AUTOMATE_LETTERS') == 'true'
    end

    def generate_income_collection_user
      Hackney::Domain::User.new.tap do |u|
        u.groups = ['income-collection']
        u.name = 'AUTOMATED SENDING - INCOME COLLECTION LETTER'
      end
    end
  end
end
