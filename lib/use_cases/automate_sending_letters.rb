module UseCases
  class AutomateSendingLetters
    def initialize(case_ready_for_automation:, case_classification_to_letter_type_map:, generate_and_store_letter:, send_income_collection_letter:)
      @case_ready_for_automation = case_ready_for_automation
      @case_classification_to_letter_type_map = case_classification_to_letter_type_map
      @generate_and_store_letter = generate_and_store_letter
      @send_income_collection_letter = send_income_collection_letter
    end

    def execute(case_priority:)
      automate_letters(case_priority: case_priority) if enviornment_allow_to_send_automated_letters?
    end

    private

    def automate_letters(case_priority:)
      validate_income_collection_letter_can_be_sent?(case_priority) if @case_ready_for_automation.execute(patch_code: case_priority.patch_code)
    end

    def validate_income_collection_letter_can_be_sent?(case_priority)
      income_collection_letters = %w[income_collection_letter_1 income_collection_letter_2]

      letter_name = @case_classification_to_letter_type_map.execute(case_priority: case_priority)

      return nil unless income_collection_letters.include?(letter_name)

      generate_letter = @generate_and_store_letter.execute(
        payment_ref: nil,
        tenancy_ref: case_priority.tenancy_ref,
        template_id: letter_name,
        user: generate_income_collection_user
      )
      @send_income_collection_letter.perform_later(document_id: generate_letter[:document_id])

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
