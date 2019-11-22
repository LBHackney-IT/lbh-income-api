module UseCases
  class SyncAndSendLetterOne
    def initialize(sync_case_priority:, fetch_patch_codes_use_cases:, send_manual_precompiled_letter:)
      @sync_case_priority = sync_case_priority
      @fetch_patch_codes_use_cases = fetch_patch_codes_use_cases
      @send_manual_precompiled_letter = send_manual_precompiled_letter
    end

    def execute
      # sync case
      # fetch cases by patch
      # send letter
    end
  end
end
