module Hackney
  module Income
    class BackgroundJobGateway
      def schedule_case_priority_sync(tenancy_ref:, leasehold: false)
        Hackney::Income::Jobs::SyncCasePriorityJob.perform_later(tenancy_ref: tenancy_ref, leasehold: leasehold)
      end

      def schedule_send_sms_msg(case_id:)
        Hackney::Income::Jobs::SendSMSJob.perform_later(case_id: case_id)
      end

      def add_action_diary_entry(tenancy_ref:, action_code:, comment:, username:)
        Hackney::Income::Jobs::AddActionDiaryEntryJob.perform_later(
          tenancy_ref: tenancy_ref,
          action_code: action_code,
          comment: comment,
          username: username
        )
      end
    end
  end
end
