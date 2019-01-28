module Hackney
  module Income
    module Jobs
      class AddActionDiaryEntryJob < ApplicationJob
        queue_as :action_diary_writer

        def max_attempts
          1
        end

        def perform(tenancy_ref:, action_code:, comment:)
          Rails.logger.info("Starting AddActionDiaryEntryJob for tenancy_ref #{tenancy_ref} and action code #{action_code}")
          income_use_case_factory.add_action_diary.execute(
            tenancy_ref: tenancy_ref,
            action_code: action_code,
            comment: comment,
            user_id: nil
          )
        end
      end
    end
  end
end
