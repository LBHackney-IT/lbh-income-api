module UseCases
  class AddActionDiaryAndSyncCase
    def initialize(sync_case_priority:, add_action_diary:)
      @sync_case_priority = sync_case_priority
      @add_action_diary = add_action_diary
    end

    def execute(tenancy_ref:, action_code:, comment:, username:)
      @add_action_diary.execute(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username
      )

      @sync_case_priority.execute(tenancy_ref: tenancy_ref)
    end
  end
end
