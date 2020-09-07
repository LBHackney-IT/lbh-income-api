module Hackney
  module Income
    class CreateInformalAgreement < CreateAgreement
      CreateAgreementError = Class.new(StandardError)

      def execute(new_agreement_params:)
        tenancy_ref = new_agreement_params[:tenancy_ref]

        case_details = find_case_details(tenancy_ref)
        return if case_details.nil?

        agreement_params = assign_agreement_params(new_agreement_params)
                           .merge(agreement_type: :informal, starting_balance: case_details[:balance])

        active_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).select(&:active?)

        if active_agreements.any?
          raise CreateAgreementError, 'There is an existing formal agreement for this tenancy' if active_agreements.any?(&:formal?)

          cancel_active_agreements(active_agreements)
        end

        new_agreement = create_agreement(agreement_params)

        add_action_diary_entry(
          tenancy_ref: tenancy_ref,
          comment: "Informal agreement created: #{agreement_params[:notes]}",
          created_by: new_agreement.created_by
        )

        new_agreement
      end
    end
  end
end
