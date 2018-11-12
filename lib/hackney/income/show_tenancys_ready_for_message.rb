module Hackney
  module Income
    class ShowTenancysReadyForMessage
      def initialize(tenancys_ready_for_message_gateway:)
        @tenancys_ready_for_message_gateway = tenancys_ready_for_message_gateway
      end

      def execute
        @tenancys_ready_for_message_gateway.get_message_level_1_tenancies
      end
    end
  end
end
