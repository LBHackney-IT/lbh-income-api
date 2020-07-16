module Hackney
  module Leasehold
    class UseCaseFactory
      def uh_lease_gateway
        Hackney::Leasehold::UniversalHousingLeaseGateway
      end

      def universal_housing_gateway
        Hackney::Leasehold::UniversalHousingGateway.new
      end

      def stored_action_gateway
        Hackney::Leasehold::StoredActionGateway.new
      end

      def sync_action_attributes
        Hackney::Leasehold::SyncActionAttributes.new(
          universal_housing_gateway: universal_housing_gateway,
          stored_action_gateway: stored_action_gateway
        )
      end
    end
  end
end
