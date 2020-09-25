module Hackney
  module Income
    class CreateCourtCaseAndSync
      def initialize(create_court_case:, add_action_diary_and_sync_case_usecase:)
        @create_court_case = create_court_case
        @add_action_diary_and_sync_case_usecase = add_action_diary_and_sync_case_usecase
      end

      def execute(court_case_params:, username: nil)
        params = {
          tenancy_ref: court_case_params[:tenancy_ref],
          court_date: court_case_params[:court_date],
          court_outcome: court_case_params[:court_outcome],
          balance_on_court_outcome_date: court_case_params[:balance_on_court_outcome_date],
          strike_out_date: court_case_params[:strike_out_date],
          terms: court_case_params[:terms],
          disrepair_counter_claim: court_case_params[:disrepair_counter_claim]
        }

        court_case = @create_court_case.execute(court_case_params: params)

        if username
          @add_action_diary_and_sync_case_usecase.execute(
            tenancy_ref: court_case_params[:tenancy_ref],
            action_code: Hackney::Tenancy::ActionCodes::COURT_DATE_SET,
            comment: 'Court case created',
            username: username
          )
        end

        court_case
      end
    end
  end
end
