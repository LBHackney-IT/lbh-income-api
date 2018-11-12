module Hackney
  module Income
    class ShowTenanciesForMessageOne
      def initialize(sql_tenancies_for_messages_gateway:)
        @sql_tenancies_for_messages_gateway = sql_tenancies_for_messages_gateway
      end

      def execute
        @sql_tenancies_for_messages_gateway.get_tenancies_for_message_1
      end
    end
  end
end
