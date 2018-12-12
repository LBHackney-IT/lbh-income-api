module Hackney
  module Income
    class StubGovNotifyGateway
      extend MessagesHelper
      EXAMPLE_TEMPLATES = example_templates

      def initialize(sms_sender_id:, api_key:, send_live_communications:, test_phone_number:, test_email_address:); end

      def send_text_message(phone_number:, template_id:, reference:, variables:); end

      def send_email(recipient:, template_id:, reference:, variables:); end

      def get_templates(type:)
        EXAMPLE_TEMPLATES
      end

      def get_sent_template(template_id:, version:, personalisation:)
        {
          "id": template_id,
          "version": version,
          "body": personalisation,
          "subject": '',
          "type": 'email'
        }
      end
    end
  end
end
