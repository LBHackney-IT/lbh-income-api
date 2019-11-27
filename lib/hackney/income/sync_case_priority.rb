module Hackney
  module Income
    class SyncCasePriority
      def initialize(prioritisation_gateway:, stored_tenancies_gateway:)
        @prioritisation_gateway = prioritisation_gateway
        @stored_tenancies_gateway = stored_tenancies_gateway
      end

      def execute(tenancy_ref:)
        priorities = @prioritisation_gateway.priorities_for_tenancy(tenancy_ref)
        case_priority = @stored_tenancies_gateway.store_tenancy(
          tenancy_ref: tenancy_ref,
          priority_band: priorities.fetch(:priority_band),
          priority_score: priorities.fetch(:priority_score),
          criteria: priorities.fetch(:criteria),
          weightings: priorities.fetch(:weightings)
        )

        check_automation_of_case = UseCases::CaseReadyForAutomation.execute(patch_code: case_priority.patch_code)

        # if check_automation_of_case == true
        #   if case_priority.classification[:send_letter_one]
        #     # generate letter_1
        #     # send letter_1
        #   end
        # end

        nil
      end
    end
  end
end
