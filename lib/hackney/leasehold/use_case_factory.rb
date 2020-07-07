module Hackney
  module Leasehold
    class UseCaseFactory
      def uh_lease_gateway
        Hackney::Leasehold::UniversalHousingLeaseGateway
      end

      def prioritisation_gateway
        Hackney::Leasehold::UniversalHousingPrioritisationGateway.new
      end
    end
  end
end
