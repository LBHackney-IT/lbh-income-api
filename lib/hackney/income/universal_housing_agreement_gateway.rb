module Hackney
  module Income
    class UniversalHousingAgreementGateway
      def self.for_tenancy(database_connection, tenancy_ref)
        sql = <<~SQL
          SELECT *
          FROM UHArag arag
          JOIN UHAragdet aragdet on arag.arag_sid = aragdet.arag_sid
          WHERE arag.tag_ref = ?
          ORDER BY aragdet.aragdet_sid
        SQL

        results = database_connection[sql, tenancy_ref].all

        return [] if results.empty?

        agreements_by_ref = results.each_with_object({}) { |agreement, acc|
          acc[agreement[:arag_ref]] = [] unless acc.key?(agreement[:arag_ref])
          acc[agreement[:arag_ref]].push(agreement)
        }

        agreements_by_ref.map(&method(:map_agreement_changes)).flatten
      end

      def self.map_agreement_changes(_, agreement_changes)
        agreement_changes.map.with_index do |agreement_change, index|
          final_update = index == agreement_changes.count - 1
          status = final_update ? agreement_change[:arag_status] : Hackney::Income::CANCELLED_ARREARS_AGREEMENT_STATUS

          {
            start_date: agreement_change[:aragdet_startdate],
            status: status,
            breached: agreement_change[:arag_breached],
            last_check_balance: agreement_change[:arag_lastcheckbal],
            last_check_date: agreement_change[:arag_lastcheckdate],
            last_check_expected_balance: agreement_change[:arag_lastexpectedbal],
            starting_balance: agreement_change[:arag_startbal],
            comment: agreement_change[:aragdet_comment],
            amount: agreement_change[:aragdet_amount],
            frequency: agreement_change[:aragdet_frequency].to_i,
            uh_id: agreement_change[:aragdet_sid]
          }
        end
      end
    end
  end
end
