module Hackney
  module Leasehold
    class SyncCaseAttributes
      def initialize(universal_housing_gateway:, stored_case_gateway:)
        @universal_housing_gateway = universal_housing_gateway
        @stored_case_gateway = stored_case_gateway
      end

      def execute(tenancy_ref:)
        case_attributes = @universal_housing_gateway.fetch(tenancy_ref)
        @stored_case_gateway.store_case(
          tenancy_ref: tenancy_ref,
          criteria: case_attributes
        )
      end
    end
  end
end
