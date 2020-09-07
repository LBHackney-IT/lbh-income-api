module Hackney
  module Income
    class CreateInformalAgreement < CreateAgreement
      CreateAgreementError = Class.new(StandardError)

      def execute(new_agreement_params:)
        tenancy_ref = new_agreement_params[:tenancy_ref]

        case_details = find_case_details(tenancy_ref)
        return if case_details.nil?

        agreement_params = {
          tenancy_ref: tenancy_ref,
          agreement_type: :informal,
          starting_balance: case_details[:balance],
          amount: new_agreement_params[:amount],
          start_date: new_agreement_params[:start_date],
          frequency: new_agreement_params[:frequency],
          created_by: new_agreement_params[:created_by],
          notes: new_agreement_params[:notes],
          initial_payment_amount: new_agreement_params[:initial_payment_amount],
          initial_payment_date: new_agreement_params[:initial_payment_date]
        }

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
