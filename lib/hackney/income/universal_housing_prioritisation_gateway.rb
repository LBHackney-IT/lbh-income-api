module Hackney
  module Income
    class UniversalHousingPrioritisationGateway
      def priorities_for_tenancy(tenancy_ref)
        Hackney::UniversalHousing::Client.with_connection do |database|
          criteria = Hackney::Income::TenancyPrioritiser::UniversalHousingCriteria.for_tenancy(database, tenancy_ref)
          { criteria: criteria }
        end
      end
    end
  end
end
