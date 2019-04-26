module Hackney
  module ServiceCharge
    class UseCaseFactory
      def get_leasehold_information
        Hackney::ServiceCharge::GetLeaseholdInformation.new(
          service_charge_gateway: Hackney::Income::UniversalHousingLeaseholdGateway.new
        )
      end

      def map_tenancy_information
        Hackney::Income::UniversalHousingLeaseholdGateway.new
      end
    end
  end
end
