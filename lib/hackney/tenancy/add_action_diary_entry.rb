require 'httparty'

module Hackney
  module Tenancy
    class AddActionDiaryEntry
      def initialize(action_diary_gateway:)
        @action_diary_gateway = action_diary_gateway
      end

      def execute(tenancy_ref:, action_code:, action_balance:, comment:, username: nil)
        Rails.logger.info('Adding comment to action diary')
        @action_diary_gateway.create_entry(tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment, username: username)
      end
    end
  end
end
