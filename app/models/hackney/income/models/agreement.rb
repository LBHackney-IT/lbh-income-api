module Hackney
  module Income
    module Models
      class Agreement < ApplicationRecord
        has_many :agreement_states, class_name: 'Hackney::Income::Models::AgreementState'
        enum agreement_type: { informal: 'informal', formal: 'formal' }
        enum frequency: { weekly: 0, monthly: 1 }

        def current_state
          Hackney::Income::Models::AgreementState.where(agreement_id: id).last&.agreement_state
        end
      end
    end
  end
end
