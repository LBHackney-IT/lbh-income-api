module Hackney
  module Income
    class ShowTenancysReadyForMessage
      def initialize(tenancies_ready_for_message_gateway:)
        @tenancies_ready_for_message_gateway = tenancies_ready_for_message_gateway
      end

      def execute
        @tenancies_ready_for_message_gateway.get_message_level_1_tenancies
      end
    end
  end
end
