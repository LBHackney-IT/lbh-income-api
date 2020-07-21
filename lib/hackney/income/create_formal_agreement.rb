module Hackney
  module Income
    class CreateFormalAgreement
      def initialize(add_action_diary:, cancel_agreement:)
        @add_action_diary = add_action_diary
        @cancel_agreement = cancel_agreement
      end

      def execute(new_agreement_params:)
        tenancy_ref = new_agreement_params[:tenancy_ref]
        court_case_id = new_agreement_params[:court_case_id]
        return if court_case_id.nil?

        court_case = Hackney::Income::Models::CourtCase.find_by_id(court_case_id)
        return if court_case.nil?

        case_details = Hackney::Income::Models::CasePriority.where(tenancy_ref: tenancy_ref).first
        return if case_details.nil?

        agreement_params = {
          tenancy_ref: tenancy_ref,
          agreement_type: :formal,
          starting_balance: case_details[:balance],
          amount: new_agreement_params[:amount],
          start_date: new_agreement_params[:start_date],
          frequency: new_agreement_params[:frequency],
          created_by: new_agreement_params[:created_by],
          current_state: 'live',
          notes: new_agreement_params[:notes],
          court_case_id: court_case.id
        }

        active_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).select(&:active?)

        if active_agreements.any?
          active_agreements.each do |agreement|
            @cancel_agreement.execute(agreement_id: agreement.id)
          end
        end

        new_agreement = Hackney::Income::Models::Agreement.create!(agreement_params)
        Hackney::Income::Models::AgreementState.create!(agreement_id: new_agreement.id, agreement_state: :live)

        @add_action_diary.execute(
          tenancy_ref: tenancy_ref,
          action_code: 'AGR',
          comment: "Formal agreement created: #{new_agreement_params[:notes]}",
          username: new_agreement_params[:created_by]
        )

        new_agreement
      end
    end
  end
end
