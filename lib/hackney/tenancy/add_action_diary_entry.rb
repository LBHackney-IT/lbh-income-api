require 'httparty'

module Hackney
  module Tenancy
    class AddActionDiaryEntry
      def initialize(action_diary_gateway:, users_gateway:)
        @action_diary_gateway = action_diary_gateway
        @users_gateway = users_gateway
      end

      def execute(tenancy_ref:, action_code:, action_balance:, comment:, user_id: nil)
        # if user_id look up
        username = user_id.nil? ? nil : @users_gateway.find_user(id: user_id)&.name

        if !user_id.nil? && username.nil?
          raise ArgumentError, 'user_id supplied does not exist'
        end

        Rails.logger.info("Adding action diary comment to #{tenancy_ref} with username '#{username}'")
        @action_diary_gateway.create_entry(tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment, username: username)
      end
    end
  end
end
