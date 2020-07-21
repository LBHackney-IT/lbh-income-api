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

        formal_agreement_params = {
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

        cancel_active_agreements(active_agreements) if active_agreements.any?

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
