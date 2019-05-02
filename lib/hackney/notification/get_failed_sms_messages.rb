module Hackney
  module Notification
    class GetFailedSMSMessages
      def initialize(notification_gateway:)
        @notification_gateway = notification_gateway
      end

      def execute
        notification_gateway.get_messages(type: 'sms', status: 'failed').map do |message|
          {
            id: message.id,
            reference: message.reference,
            phone_number: message.phone_number
          }
        end
      end

      private

      attr_reader :notification_gateway
    end
  end
end
