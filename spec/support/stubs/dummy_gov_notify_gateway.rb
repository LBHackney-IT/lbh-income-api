module Hackney
  module Notification
    class DummyGovNotifyGateway
      extend MessagesHelper
      EXAMPLE_TEMPLATES = example_templates

      def initialize(sms_sender_id:, api_key:, send_live_communications:, test_phone_number:, test_email_address:, test_physical_address: nil); end

      def get_template_name(template_id)
        get_templates&.find { |template_item| template_item[:id] == template_id }&.fetch(:name) || template_id
      end

      def send_text_message(phone_number:, template_id:, reference:, variables:)
        Hackney::Notification::Domain::NotificationReceipt.new(body: 'DummyGovNotifyGateway body')
      end

      def send_email(recipient:, template_id:, reference:, variables:)
        Hackney::Notification::Domain::NotificationReceipt.new(body: 'DummyGovNotifyGateway body')
      end

      def send_precompiled_letter(unique_reference:, letter_pdf:)
        Hackney::Notification::Domain::NotificationReceipt.new(body: 'DummyGovNotifyGateway body')
      end

      def get_templates(type: nil)
        EXAMPLE_TEMPLATES
      end
    end
  end
end
