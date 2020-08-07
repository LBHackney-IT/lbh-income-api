module Hackney
  module Income
    class SyncCasePriority
      def initialize(prioritisation_gateway:, stored_worktray_item_gateway:, automate_sending_letters:)
        @automate_sending_letters = automate_sending_letters
        @prioritisation_gateway = prioritisation_gateway
        @stored_worktray_item_gateway = stored_worktray_item_gateway
      end

      def execute(tenancy_ref:)
        priorities = @prioritisation_gateway.priorities_for_tenancy(tenancy_ref)
        case_priority = @stored_worktray_item_gateway.store_worktray_item(
          tenancy_ref: tenancy_ref,
          criteria: priorities.fetch(:criteria)
        )

        @automate_sending_letters.execute(case_priority: case_priority) unless case_priority.paused?

        nil
      end
    end
  end
end
