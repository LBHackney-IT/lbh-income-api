module Hackney
  module Income
    class UniversalHousingAgreementGateway
      def initialize(universal_housing_client)
        @universal_housing_client = universal_housing_client
      end

      def for_tenancy(tenancy_ref:)
        sql = <<~SQL
          SELECT *
          FROM arag
          WHERE arag.tag_ref = ?
        SQL

        results = @universal_housing_client[sql, tenancy_ref].all

        results.map do |agreement|
          {
            startdate: agreement[:arag_startdate]
          }
        end
      end
    end
  end
end
