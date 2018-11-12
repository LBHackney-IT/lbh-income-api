module Hackney
  module Income
    class SqlTenanciesForMessagesGateway
      def get_tenancies_for_message_1
        Hackney::Income::Models::Tenancy
          .where(priority_band: 'green')
          .where('days_in_arrears >= ?', 5)
          .where('balance >= ?', 10.00)
          .where(active_agreement: false)
          .where('is_paused_until < ? OR is_paused_until is null', Date.today)
      end
    end
  end
end
