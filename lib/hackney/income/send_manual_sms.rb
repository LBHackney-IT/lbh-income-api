require 'phonelib'

module Hackney
  module Income
    class SendManualSms
      def initialize(notification_gateway:, add_action_diary_usecase:)
        @notification_gateway = notification_gateway
        @add_action_diary_usecase = add_action_diary_usecase
      end

      def execute(user_id:, tenancy_ref:, template_id:, phone_number:, reference:, variables:)
        phone = Phonelib.parse(phone_number)
        if phone.valid?
          notification_receipt = @notification_gateway.send_text_message(
            phone_number: phone.full_e164,
            template_id: template_id,
            reference: reference,
            variables: variables
          )
          Rails.logger.info("Manual SMS sent using template_id: #{template_id}, reference was: #{reference}")

          template_name = @notification_gateway.get_template_name(template_id)
          @add_action_diary_usecase.execute(
            user_id: user_id,
            tenancy_ref: tenancy_ref,
            action_code: Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE,
            comment: "#{template_name}' SMS sent to '#{phone.full_e164}' with content '#{notification_receipt.body_without_newlines}'"
          )
        else
          Rails.logger.warn("Invalid phone number when trying to send manual SMS (reference: '#{reference}') using template_id: #{template_id}, ignoring")
        end
      end
    end
  end
end
