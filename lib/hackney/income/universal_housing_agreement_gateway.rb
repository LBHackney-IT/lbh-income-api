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
          JOIN aragdet on arag.arag_sid = aragdet.arag_sid
          WHERE arag.tag_ref = ?
        SQL

        results = @universal_housing_client[sql, tenancy_ref].all

        results.map do |agreement|
          {
            start_date: agreement[:aragdet_startdate],
            breached: agreement[:arag_breached],
            last_check_balance: agreement[:arag_lastcheckbal],
            last_check_date: agreement[:arag_lastcheckdate],
            last_check_expected_balance: agreement[:arag_lastexpectedbal],
            starting_balance: agreement[:arag_startbal],
            comment: agreement[:aragdet_comment],
            amount: agreement[:aragdet_amount],
            frequency: agreement[:aragdet_frequency].to_i
          }
        end
      end
    end
  end
end
