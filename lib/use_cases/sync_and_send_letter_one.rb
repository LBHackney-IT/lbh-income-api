module UseCases
  class SyncAndSendLetterOne
    def initialize(sync_case_priority:, fetch_cases_by_patch:, send_manual_precompiled_letter:)
      @sync_case_priority = sync_case_priority
      @fetch_cases_by_patch = fetch_cases_by_patch
      @send_manual_precompiled_letter = send_manual_precompiled_letter
    end

    def execute(tenancy_ref:, username: nil, payment_ref: nil, template_id:, unique_reference:, letter_pdf:)
      @sync_case_priority.execute(tenancy_ref: tenancy_ref)
      @fetch_cases_by_patch.execute
      @send_manual_precompiled_letter.execute(
        username: username,
        payment_ref: payment_ref,
        template_id: template_id,
        unique_reference: unique_reference,
        letter_pdf: letter_pdf
      )
    end
  end
end
