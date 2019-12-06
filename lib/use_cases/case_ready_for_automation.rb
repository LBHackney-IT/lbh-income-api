module UseCases
  class CaseReadyForAutomation
    def execute(patch_code:)
      patch_codes_allowed_for_automation.include?(patch_code)
    end

    private

    def patch_codes_allowed_for_automation
      patch_codes_allowed_for_automation_env.to_s.split(',').map(&:squish)
    end

    def patch_codes_allowed_for_automation_env
      ENV.fetch('PATCH_CODES_FOR_LETTER_AUTOMATION')
    end
  end
end
