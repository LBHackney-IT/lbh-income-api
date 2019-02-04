module Hackney
  module Income
    class DummyGovNotifyGateway
      extend MessagesHelper
      EXAMPLE_TEMPLATES = example_templates

      def initialize(sms_sender_id:, api_key:, send_live_communications:, test_phone_number:, test_email_address:); end

      def get_template_name(id); end

      def send_text_message(phone_number:, template_id:, reference:, variables:)
        Hackney::Income::Domain::NotificationReceipt.new(body: 'DummyGovNotifyGateway body')
      end

      def send_email(recipient:, template_id:, reference:, variables:)
        Hackney::Income::Domain::NotificationReceipt.new(body: 'DummyGovNotifyGateway body')
      end

      def get_templates(type:)
        EXAMPLE_TEMPLATES
      end
    end
  end
end
