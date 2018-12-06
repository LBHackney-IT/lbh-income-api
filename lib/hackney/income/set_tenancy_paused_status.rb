module Hackney
  module Income
    class SetTenancyPausedStatus
      def initialize(gateway:, add_action_diary_usecase:)
        @gateway = gateway
        @add_action_diary_usecase = add_action_diary_usecase
      end

      def execute(user_id:, tenancy_ref:, until_date:, pause_reason:, pause_comment:, action_code:)
        @gateway.set_paused_until(
          tenancy_ref: tenancy_ref,
          until_date: until_date,
          pause_reason: pause_reason,
          pause_comment: pause_comment
        )

        @add_action_diary_usecase.execute(
          user_id: user_id,
          tenancy_ref: tenancy_ref,
          action_code: action_code,
          action_balance: nil, # TODO: this should not be required
          comment: "#{pause_reason}: Paused to #{Date.parse(until_date)}. #{pause_comment}"
        )
      end
    end
  end
end
