module UseCases
  class FetchCasesByPatch
    PATCH_CODE = ENV.fetch('PATCH_CODE').freeze

    def execute
      Hackney::Income::Models::CasePriority.where(patch_code: PATCH_CODE)
    end
  end
end
