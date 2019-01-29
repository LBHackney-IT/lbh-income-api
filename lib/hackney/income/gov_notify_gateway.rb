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
        responce = @client.send_sms(
          phone_number: pre_release_phone_number(phone_number),
          template_id: template_id,
          personalisation: variables,
          reference: reference,
          sms_sender_id: @sms_sender_id
        )
        create_notification_receipt(responce)
      end

      def send_email(recipient:, template_id:, reference:, variables:)
        responce = @client.send_email(
          email_address: pre_release_email(recipient),
          template_id: template_id,
          personalisation: variables,
          reference: reference
        )
        create_notification_receipt(responce)
      end

      def get_template_name(template_id)
        get_templates&.find { |template_item| template_item[:id] == template_id }&.fetch(:name) || template_id
      end

      def get_templates(type: nil)
        @all_templates ||= all_templates_request
        if type.nil?
          @all_templates
        else
          @all_templates.select { |template| template[:type] == type }
        end
      end

      private

      def create_notification_receipt(responce)
        body = responce.content&.fetch('body', nil)
        Hackney::Income::Domain::NotificationReceipt.new(body: body)
      end

      def all_templates_request
        @client.get_all_templates.collection.map do |template|
          { id: template.id, type: template.type, name: template.name, body: template.body }
        end
      end

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
