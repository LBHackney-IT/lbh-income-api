require 'notifications/client'

module Hackney
  module Notification
    class GovNotifyGateway
      def initialize(sms_sender_id:, api_key:, send_live_communications:, test_phone_number: nil, test_email_address: nil)
        @api_key = api_key
        @sms_sender_id = sms_sender_id
        @send_live_communications = send_live_communications

        # TODO: do something with these
        @test_phone_number = test_phone_number
        @test_email_address = test_email_address
      end

      def send_text_message(phone_number:, template_id:, reference:, variables:)
        responce = client.send_sms(
          phone_number: pre_release_phone_number(phone_number),
          template_id: template_id,
          personalisation: variables,
          reference: reference,
          sms_sender_id: @sms_sender_id
        )
        create_notification_receipt(responce)
      end

      def send_email(recipient:, template_id:, reference:, variables:)
        responce = client.send_email(
          email_address: pre_release_email(recipient),
          template_id: template_id,
          personalisation: variables,
          reference: reference
        )
        create_notification_receipt(responce)
      end

      def send_precompiled_letter(unique_reference:, letter_pdf:)
        postage = 'second' # second is the default
        response = client.send_precompiled_letter(unique_reference, letter_pdf, postage)
        # success returns a reference and postage
        body = "#{response.reference} sent via #{response.postage} postage"
        Hackney::Notification::Domain::NotificationReceipt.new(body: body, message_id: response.id)
      end

      def precompiled_letter_state(message_id:)
        response = client.get_notification(message_id)
        { status: response.status }
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

      def get_messages(type: nil, status: nil)
        messages = []
        last_id = nil
        while (collection = fetch_messages(type: type, status: status, older_than: last_id).collection.presence)
          last_id = collection.last.id
          messages += collection
        end
        messages
      end

      private

      def client
        @client ||= Notifications::Client.new(@api_key)
      end

      def create_notification_receipt(responce)
        body = responce.content&.fetch('body', nil)
        Hackney::Notification::Domain::NotificationReceipt.new(body: body)
      end

      def all_templates_request
        client.get_all_templates.collection.map do |template|
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

      def fetch_messages(type: nil, status: nil, older_than: nil)
        client.get_notifications({
          template_type: type,
          status: status,
          older_than: older_than
        }.compact)
      end
    end
  end
end
