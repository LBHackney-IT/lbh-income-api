module Hackney
  module Income
    class SendSms
      def initialize(notification_gateway:, add_action_diary_usecase:)
        @notification_gateway = notification_gateway
        @add_action_diary_usecase = add_action_diary_usecase
      end

      def execute(user_id:, tenancy_ref:, template_id:, phone_number:, reference:, variables:)
        # something will be done with the tenancy_ref here later
        @notification_gateway.send_text_message(
          phone_number: phone_number,
          template_id: template_id,
          reference: reference,
          variables: variables
        )
        @add_action_diary_usecase.execute(
          user_id: user_id,
          tenancy_ref: tenancy_ref,
          action_code: '', # this needs to be decided
          action_balance: nil,
          comment: "An SMS has been sent to '#{phone_number}'"
        )
      end
    end
  end
end
