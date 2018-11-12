module Hackney
  module Income
    class SqlTenanciesForMessagesGateway
      def get_tenancies_for_message_1
        Hackney::Income::Models::Tenancy.tenancies_for_message_1
      end
    end
  end
end
