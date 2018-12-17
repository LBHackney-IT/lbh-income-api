require 'notifications/client'

module Hackney
  module Income
    class GovNotifyGateway
      def initialize(sms_sender_id:, api_key:, send_live_communications:, test_phone_number:, test_email_address:)
        @sms_sender_id = sms_sender_id
        @client = Notifications::Client.new(api_key)
        @send_live_communications = send_live_communications
        @test_phone_number = test_phone_number
        @test_email_address = test_email_address
      end

      def send_text_message(phone_number:, template_id:, reference:, variables:)
        @client.send_sms(
          phone_number: pre_release_phone_number(phone_number),
          template_id: template_id,
          personalisation: variables,
          reference: reference,
          sms_sender_id: @sms_sender_id
        )
      end

      def send_email(recipient:, template_id:, reference:, variables:)
        @client.send_email(
          email_address: pre_release_email(recipient),
          template_id: template_id,
          personalisation: variables,
          reference: reference
        )
      end

      def get_templates(type:)
        @client.get_all_templates(type: type).collection.map do |template|
          { id: template.id, name: template.name, body: template.body }
        end
      end

      def get_sent_template(template_id:, version:)
        @client.get_template_version(
          template_id, version
        )
      end

      private

      def pre_release_phone_number(phone_number)
        return phone_number if @send_live_communications
        @test_phone_number
      end

      def pre_release_email(email)
        return email if @send_live_communications
        @test_email_address
      end
    end
  end
end
