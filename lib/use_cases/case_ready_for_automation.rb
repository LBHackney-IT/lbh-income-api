module UseCases
  class CaseReadyForAutomation
    def execute(patch_code:)
      patch_codes_allowed_for_automation = ENV.fetch('PATCH_CODES_FOR_LETTER_AUTOMATION').split(',')
      patch_codes_allowed_for_automation.include? patch_code
    end
  end
end
