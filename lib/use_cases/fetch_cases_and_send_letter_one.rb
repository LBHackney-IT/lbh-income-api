module UseCases
  class FetchCasesAndSendLetterOne
    def initialize(fetch_cases_by_patch:, send_manual_precompiled_letter:)
      @fetch_cases_by_patch = fetch_cases_by_patch
      @send_manual_precompiled_letter = send_manual_precompiled_letter
    end

    def execute(tenancy_ref:, username: nil, payment_ref: nil, template_id:, unique_reference:, letter_pdf:)
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
