require 'phonelib'

module Hackney
  module Notification
    class SendManualSms < BaseManualGateway
      def execute(username:, tenancy_ref:, template_id:, phone_number:, reference:, variables:)
        phone = Phonelib.parse(phone_number)
        if phone.valid? && govnotify_valid?(phone.full_e164)
          notification_receipt = @notification_gateway.send_text_message(
            phone_number: phone.full_e164,
            template_id: template_id,
            reference: reference,
            variables: variables
          )
          Rails.logger.info("Manual SMS sent using template_id: #{template_id}, reference was: #{reference}")

          template_name = @notification_gateway.get_template_name(template_id)
          @add_action_diary_and_pause_case_usecase.execute(
            username: username,
            tenancy_ref: tenancy_ref,
            action_code: Hackney::Notification::ManualActionCode.get_by_sms_template_name(template_name: template_name),
            comment: "#{template_name}' SMS sent to '#{phone.full_e164}' with content '#{notification_receipt.body_without_newlines}'"
          )
        else
          error_msg = "Invalid phone number when trying to send manual SMS (reference: '#{reference}') using template_id: #{template_id}"
          Rails.logger.warn(error_msg)
          raise ArgumentError, error_msg
        end
      end

      private

      def govnotify_valid?(phone)
        phone.match('^\\+447[\\d]{9}$')
      end
    end
  end
end
