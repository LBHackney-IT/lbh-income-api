module Hackney
  module Income
    module Jobs
      class SyncCasePriorityJob < ApplicationJob
        queue_as :default

        def perform(tenancy_ref:)
          income_use_case_factory.sync_case_priority.execute(tenancy_ref: tenancy_ref)
        end
      end
    end
  end
end
