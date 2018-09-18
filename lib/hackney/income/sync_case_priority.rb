module Hackney
  module Income
    class SyncCasePriority
      def initialize(prioritisation_gateway:, stored_tenancies_gateway:)
        @prioritisation_gateway = prioritisation_gateway
        @stored_tenancies_gateway = stored_tenancies_gateway
      end

      def execute(tenancy_ref:)
        priorities = @prioritisation_gateway.priorities_for_tenancy(tenancy_ref)
        @stored_tenancies_gateway.store_tenancy(
          tenancy_ref: tenancy_ref,
          priority_band: priorities.fetch(:priority_band),
          priority_score: priorities.fetch(:priority_score),
          criteria: priorities.fetch(:criteria),
          weightings: priorities.fetch(:weightings)
        )

        nil
      end
    end
  end
end
