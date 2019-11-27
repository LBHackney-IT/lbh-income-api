module UseCases
  class FetchCasesAndSendLetterOne
    def initialize(case_ready_for_automation:, send_manual_precompiled_letter:)
      @case_ready_for_automation = case_ready_for_automation
      @send_manual_precompiled_letter = send_manual_precompiled_letter
    end

    def execute(patch_code:, case_priority:)
      @case_ready_for_automation.execute(patch_code: patch_code, case_priority: case_priority)
    end
  end
end
