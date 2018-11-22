module Hackney
  module Income
    class SendEmail
      def initialize(notification_gateway:, add_action_diary_usecase:)
        # @tenancy_gateway = tenancy_gateway
        @notification_gateway = notification_gateway
        @add_action_diary_usecase = add_action_diary_usecase
      end

      def execute(user_id:, tenancy_ref:, recipient:, template_id:, reference:, variables:)
        # tenancy = @tenancy_gateway.get_tenancy(tenancy_ref: tenancy_ref)
        # FIXME: currently not getting email addresses or saving!
        @notification_gateway.send_email(
          recipient: recipient,
          template_id: template_id,
          reference: reference,
          variables: variables
        )
        @add_action_diary_usecase.execute(
          user_id: user_id,
          tenancy_ref: tenancy_ref,
          action_code: '', # this needs to be decided
          action_balance: nil,
          comment: "An email has been sent to '#{recipient}'"
        )
      end
    end
  end
end
