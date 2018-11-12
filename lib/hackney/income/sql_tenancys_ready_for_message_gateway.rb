module Hackney
  module Income
    class SqlTenancysReadyForMessageGateway
      def get_message_level_1_tenancies
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
