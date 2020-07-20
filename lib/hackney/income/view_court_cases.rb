module Hackney
  module Income
    class ViewCourtCases
      def execute(tenancy_ref:)
        requested_cases = Hackney::Income::Models::CourtCase.where(tenancy_ref: tenancy_ref)

        return [] unless requested_cases.any?

        requested_cases
      end
    end
  end
end
