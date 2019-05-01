module Hackney
  module Notification
    class ManualActionCode
      class << self
        def get_by_sms_template_name(template_name:)
          if template_name.start_with?('Green')
            Hackney::Tenancy::ActionCodes::MANUAL_GREEN_SMS_ACTION_CODE
          elsif template_name.start_with?('Amber')
            Hackney::Tenancy::ActionCodes::MANUAL_AMBER_SMS_ACTION_CODE
          else
            warn("unknown sms template: #{template_name}")
            Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE
          end
        end

        private

        def warn(message)
          Rails.logger.warn('Notification::ManualActionCode') { message }
        end
      end
    end
  end
end
