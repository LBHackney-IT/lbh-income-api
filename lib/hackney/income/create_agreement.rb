module Hackney
  module Income
    class CreateAgreement
      def execute(new_agreement_params:)
        tenancy_ref = new_agreement_params[:tenancy_ref]
        case_details = Hackney::Income::Models::CasePriority.where(tenancy_ref: tenancy_ref)

        agreement_params = {
          tenancy_ref: tenancy_ref,
          agreement_type: new_agreement_params[:agreement_type],
          starting_balance: case_details.first[:balance],
          amount: new_agreement_params[:amount],
          start_date: new_agreement_params[:start_date],
          frequency: new_agreement_params[:frequency],
          created_by: new_agreement_params[:created_by],
          current_state: 'live'
        }

        active_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).select(&:active?)

        if active_agreements.any?
          active_agreements.each do |agreement|
            Hackney::Income::Models::AgreementState.create!(agreement_id: agreement.id, agreement_state: :cancelled)
          end
        end

        new_agreement = Hackney::Income::Models::Agreement.create!(agreement_params)
        Hackney::Income::Models::AgreementState.create!(agreement_id: new_agreement.id, agreement_state: :live)

        new_agreement
      end
    end
  end
end
