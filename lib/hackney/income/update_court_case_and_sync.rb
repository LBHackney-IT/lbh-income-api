module Hackney
  module Income
    class UpdateCourtCaseAndSync
      include CourtOutcomeHelper

      def initialize(update_court_case:, add_action_diary_and_sync_case:)
        @update_court_case = update_court_case
        @add_action_diary_and_sync_case = add_action_diary_and_sync_case
      end

      def execute(court_case_params:, username: nil)
        court_case = @update_court_case.execute(court_case_params: court_case_params)

        return if court_case.nil?

        if username.present?
          tenancy_ref = court_case[:tenancy_ref]
          court_outcome = court_case[:court_outcome]
          @add_action_diary_and_sync_case.execute(
            username: username,
            tenancy_ref: tenancy_ref,
            action_code: 'IC6',
            comment: "Court outcome added: #{human_readable_outcome(court_outcome)}"
          )
        end

        court_case
      end
    end
  end
end
