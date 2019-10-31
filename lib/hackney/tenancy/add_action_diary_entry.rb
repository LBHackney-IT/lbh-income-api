require 'httparty'

module Hackney
  module Tenancy
    class AddActionDiaryEntry
      def initialize(action_diary_gateway:)
        @action_diary_gateway = action_diary_gateway
      end

      def execute(tenancy_ref:, action_code:, comment:, username: nil, date: nil)
        date = date.nil? ? DateTime.now : date

        Rails.logger.info("Adding action diary comment to #{tenancy_ref} with username '#{username}'")
        @action_diary_gateway.create_entry(tenancy_ref: tenancy_ref, action_code: action_code, comment: comment, username: username, date: date)
      end
    end
  end
end
