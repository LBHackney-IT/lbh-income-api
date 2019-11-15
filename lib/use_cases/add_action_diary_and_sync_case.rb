module UseCases
  class AddActionDiaryAndSyncCase
    def initialize(sync_case_priority:, action_diary_gateway:)
      @sync_case_priority = sync_case_priority
      @action_diary_gateway = action_diary_gateway
    end

    def execute(tenancy_ref:, action_code:, comment:, username:)
      @action_diary_gateway.create_entry(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username
      )

      @sync_case_priority.execute(tenancy_ref: tenancy_ref)
    end
  end
end
