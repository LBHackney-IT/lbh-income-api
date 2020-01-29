module UseCases
  class AddActionDiaryAndPauseCase
    def initialize(sql_pause_tenancy_gateway:, add_action_diary:)
      @sql_pause_tenancy_gateway = sql_pause_tenancy_gateway
      @add_action_diary = add_action_diary
    end

    def execute(tenancy_ref:, action_code:, comment:, username:)
      @add_action_diary.execute(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username
      )

      return unless code_pauses_case?(action_code)

      @sql_pause_tenancy_gateway.set_paused_until(
        tenancy_ref: tenancy_ref,
        until_date: Date.tomorrow.beginning_of_day.iso8601,
        pause_reason: 'Other',
        pause_comment: "Paused for resync at #{Date.tomorrow}"
      )
    end

    private

    def code_pauses_case?(code)
      Hackney::Tenancy::ActionCodes::CODES_THAT_PAUSES_CASES.include?(code)
    end
  end
end
