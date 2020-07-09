module Hackney
  module Leasehold
    class SyncCaseAttributes
      def initialize(prioritisation_gateway:, stored_tenancies_gateway:)
        @prioritisation_gateway = prioritisation_gateway
        @stored_tenancies_gateway = stored_tenancies_gateway
      end

      def execute(tenancy_ref:)
        priorities = @prioritisation_gateway.priorities_for_lease(tenancy_ref)
        @stored_tenancies_gateway.store_tenancy(
          tenancy_ref: tenancy_ref,
          criteria: priorities.fetch(:criteria)
        )
      end
    end
  end
end
