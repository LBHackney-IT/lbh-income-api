module Hackney
  module Income
    class CreateAgreement
      def self.execute(new_agreement_params:)
        case_details = Hackney::Income::Models::CasePriority.where(tenancy_ref: new_agreement_params[:tenancy_ref])
        # case_details is as array, but I think each tag_ref has one case priority?
        # In the Case model it say: 'has_one :case_priority'

        agreement_params = {
          tenancy_ref: new_agreement_params[:tenancy_ref],
          agreement_type: new_agreement_params[:agreement_type],
          starting_balance: case_details.first[:balance],
          amount: new_agreement_params[:amount],
          start_date: new_agreement_params[:start_date],
          frequency: new_agreement_params[:frequency],
          current_state: 'active' # Need some magic to determine state of agreement - here? or elsewhere?
          # current_state: new_agreement_params[:current_state] || 'active'
        }

        Hackney::Income::Models::Agreement.create!(agreement_params)
        Hackney::Income::Models::AgreementState.create!(agreement_id: new_agreement.id, agreement_state: agreement_params[:current_state])

        # Is calling another use case bad? Should I just build the response using new_agreement here again instead?
        Hackney::Income::ViewAgreements.execute(tenancy_ref: new_agreement_params[:tenancy_ref])[:agreements].last
      end
    end
  end
end
