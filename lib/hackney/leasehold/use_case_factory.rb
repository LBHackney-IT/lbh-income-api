module Hackney
  module Leasehold
    class UseCaseFactory
      def uh_lease_gateway
        Hackney::Leasehold::UniversalHousingLeaseGateway
      end

      def universal_housing_gateway
        Hackney::Leasehold::UniversalHousingGateway.new
      end

      def stored_case_gateway
        Hackney::Leasehold::StoredCasesGateway.new
      end

      def sync_case_attributes
        Hackney::Leasehold::SyncCaseAttributes.new(
          universal_housing_gateway: universal_housing_gateway,
          stored_case_gateway: stored_case_gateway
        )
      end
    end
  end
end
