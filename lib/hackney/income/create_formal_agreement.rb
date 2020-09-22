module Hackney
  module Income
    class CreateFormalAgreement < CreateAgreement
      def execute(new_agreement_params:)
        tenancy_ref = new_agreement_params[:tenancy_ref]
        court_case_id = new_agreement_params[:court_case_id]
        return if court_case_id.nil?

        court_case = Hackney::Income::Models::CourtCase.find_by_id(court_case_id)
        return if court_case.nil?

        case_details = find_case_details(tenancy_ref)
        return if case_details.nil?

        formal_agreement_params = assign_agreement_params(new_agreement_params)
                                  .merge(
                                    agreement_type: :formal,
                                    starting_balance: court_case.balance_on_court_outcome_date,
                                    court_case_id: court_case.id
                                  )

        active_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).select(&:active?)

        cancel_active_agreements(active_agreements, cancelled_by: new_agreement_params[:created_by]) if active_agreements.any?

        new_agreement = create_agreement(formal_agreement_params)

        add_action_diary_entry(
          tenancy_ref: tenancy_ref,
          comment: "Formal agreement created: #{formal_agreement_params[:notes]}",
          created_by: new_agreement.created_by
        )

        new_agreement
      end
    end
  end
end
