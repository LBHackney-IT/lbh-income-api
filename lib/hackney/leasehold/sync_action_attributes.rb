module Hackney
  module Leasehold
    class SyncActionAttributes
      def initialize(universal_housing_gateway:, stored_action_gateway:)
        @universal_housing_gateway = universal_housing_gateway
        @stored_action_gateway = stored_action_gateway
      end

      def execute(tenancy_ref:)
        action_attributes = @universal_housing_gateway.fetch(tenancy_ref)
        @stored_action_gateway.store_action(
            tenancy_ref: tenancy_ref,
            attributes: action_attributes
        )
      end
    end
  end
end
