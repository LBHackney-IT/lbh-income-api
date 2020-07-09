module Hackney
  module Leasehold
    class UseCaseFactory
      def uh_lease_gateway
        Hackney::Leasehold::UniversalHousingLeaseGateway
      end

      def prioritisation_gateway
        Hackney::Leasehold::UniversalHousingPrioritisationGateway.new
      end

      def sync_case_attributes
        Hackney::Leasehold::SyncCaseAttributes.new(
          prioritisation_gateway: prioritisation_gateway,
          stored_tenancies_gateway: stored_tenancies_gateway
        )
      end
    end
  end
end
