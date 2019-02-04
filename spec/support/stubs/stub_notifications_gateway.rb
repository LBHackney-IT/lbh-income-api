module Hackney
  module Income
    class StubNotificationsGateway
      DEFAULT_TEMPLATES = [
        { id: '00001', name: 'Quick Template', body: 'quick ((first name))!', subject: nil },
        { id: '00002', name: 'Where Are You?', body: 'where are you from ((title)) ((last name))??', subject: nil },
        { id: '00003', name: 'Email', body: 'Sending emails is cool and fun', subject: 'Hi ((name))!' },
        { id: '00004', name: 'A Quicker Template', body: "a body\n should be here?", subject: nil }
      ].freeze

      private_constant :DEFAULT_TEMPLATES
      attr_reader :last_text_message, :last_email

      def initialize(templates: DEFAULT_TEMPLATES, sms_sender_id: nil, api_key: nil, last_text_message: nil)
        @templates = templates
        @last_text_message = nil
        @last_email = nil
      end

      def get_template_name(id)
        get_template(id)&.fetch(:name, nil)
      end

      def get_text_templates
        @templates
      end

      def get_email_templates
        @templates
      end

      def send_text_message(phone_number:, template_id:, reference:, variables:)
        @last_text_message = {
          phone_number: phone_number,
          template_id: template_id,
          reference: reference,
          variables: variables
        }
        body = get_template(template_id)&.fetch(:body, nil)
        Hackney::Income::Domain::NotificationReceipt.new(body: body)
      end

      def send_email(recipient:, template_id:, reference:, variables:)
        @last_email = {
          recipient: recipient,
          template_id: template_id,
          reference: reference,
          variables: variables
        }
        body = get_template(template_id)&.fetch(:body, nil)
        Hackney::Income::Domain::NotificationReceipt.new(body: body)
      end

      private

      def get_template(id)
        @templates.find { |template| template[:id] == id }
      end
    end
  end
end
