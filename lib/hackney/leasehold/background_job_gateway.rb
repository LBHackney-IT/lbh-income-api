module Hackney
  module Leasehold
    class BackgroundJobGateway
      def schedule_case_priority_sync(tenancy_ref:)
        Hackney::Income::Jobs::SyncCasePriorityJob.perform_later(tenancy_ref: tenancy_ref)
      end
    end
  end
end
