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
            start_date: agreement[:arag_startdate],
            breached: agreement[:arag_breached],
            starting_balance: agreement[:arag_startbal],
            comment: agreement[:arag_comment]
          }
        end
      end
    end
  end
end
