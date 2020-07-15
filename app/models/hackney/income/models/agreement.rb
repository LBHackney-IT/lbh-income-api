module Hackney
  module Income
    module Models
      class Agreement < ApplicationRecord
        ACTIVE_STATES = %w[live breached].freeze

        validates_presence_of :agreement_type
        has_many :agreement_states, class_name: 'Hackney::Income::Models::AgreementState'
        enum agreement_type: { informal: 'informal', formal: 'formal' }
        enum frequency: { weekly: 0, monthly: 1, fortnightly: 2, '4 weekly': 3 }

        def current_state
          Hackney::Income::Models::AgreementState.where(agreement_id: id).last&.agreement_state
        end

        def active?
          ACTIVE_STATES.include?(current_state)
        end
      end
    end
  end
end
