module UseCases
  class AutomateSendingLetters
    def initialize(case_ready_for_automation:, check_case_classification_and_letter:, generate_and_store_letter:, send_income_collection_letter:)
      @case_ready_for_automation = case_ready_for_automation
      @check_case_classification_and_letter = check_case_classification_and_letter
      @generate_and_store_letter = generate_and_store_letter
      @send_income_collection_letter = send_income_collection_letter
    end

    def execute(case_priority:)
      automate_letters(case_priority: case_priority) if enviornment_allow_to_send_automated_letters?
    end

    private

    def automate_letters(case_priority:)
      # automted_user = Hackney::Domain::User.new.tap do |u|
      #   u.groups = ['income-collection']
      #   u.name = "SYSTEM - RENTS"
      # end
      # Need to test this

      if @case_ready_for_automation.execute(patch_code: case_priority[:patch_code])
        letter_name = @check_case_classification_and_letter.execute(case_priority: case_priority)
        if letter_name == 'income_collection_letter_1' || letter_name == 'income_collection_letter_2'
          generate_letter = @generate_and_store_letter.execute(tenancy_ref: case_priority[:tenancy_ref], template_id: letter_name, user: automted_user)
          send_letter_one = @send_income_collection_letter.perform_later(document_id: generate_letter[:document_id])
        end
      end
    end

    def enviornment_allow_to_send_automated_letters?
      ENV.fetch('CAN_AUTOMATE_LETTERS') == 'true'
    end
  end
end
