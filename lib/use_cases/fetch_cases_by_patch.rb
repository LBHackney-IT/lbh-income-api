module UseCases
  class FetchCasesByPatch
    def execute(patch_code:)
      raise ArgumentError unless list_of_patch_codes(patch_code).present?

      Hackney::Income::Models::CasePriority.where(patch_code: list_of_patch_codes(patch_code))
    end

    private

    def list_of_patch_codes(patch_code)
      patch_codes = ENV.fetch('PATCH_CODE')

      return patch_code if patch_codes.include? patch_code
    end
  end
end
