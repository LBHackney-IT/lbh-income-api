require 'phonelib'

module Hackney
  module Income
    class SendAutomatedSms
      def initialize(notification_gateway:, background_job_gateway:)
        @notification_gateway = notification_gateway
        @background_job_gateway = background_job_gateway
      end

      def execute(tenancy_ref:, template_id:, phone_number:, reference:, variables:)
        phone = Phonelib.parse(phone_number)
        if phone.valid?
          notification_receipt = @notification_gateway.send_text_message(
            phone_number: phone.full_e164,
            template_id: template_id,
            reference: reference,
            variables: variables
          )
          Rails.logger.info("Automated SMS sent using template_id: #{template_id}, reference was: #{reference}")

          template_name = @notification_gateway.get_template_name(template_id)
          @background_job_gateway.add_action_diary_entry(
            tenancy_ref: tenancy_ref,
            action_code: Hackney::Tenancy::ActionCodes::AUTOMATED_SMS_ACTION_CODE,
            comment: "'#{template_name}' SMS sent to '#{phone.full_e164}' with content '#{notification_receipt.body_without_newlines}'"
          )
        else
          # don't log the phone number to keep our logs free from personal data
          Rails.logger.warn("Invalid phone number when trying to send SMS for reference: '#{reference}' using template_id: #{template_id}, skipping")
        end
      end
    end
  end
end
