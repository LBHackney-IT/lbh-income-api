module Hackney
  module Income
    class SyncCasePriority
      def initialize(prioritisation_gateway:, stored_tenancies_gateway:, automate_sending_letters:)
        @automate_sending_letters = automate_sending_letters
        @prioritisation_gateway = prioritisation_gateway
        @stored_tenancies_gateway = stored_tenancies_gateway
      end

      def execute(tenancy_ref:)
        priorities = @prioritisation_gateway.priorities_for_tenancy(tenancy_ref)
        case_priority = @stored_tenancies_gateway.store_tenancy(
          tenancy_ref: tenancy_ref,
          criteria: priorities.fetch(:criteria)
        )

        @automate_sending_letters.execute(case_priority: case_priority) unless case_priority.paused?

        nil
      end
    end
  end
end
