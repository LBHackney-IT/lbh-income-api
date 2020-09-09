module Hackney
  module Income
    module Models
      class Agreement < ApplicationRecord
        ACTIVE_STATES = %w[live breached].freeze

        validates_presence_of :agreement_type, :frequency
        validates_presence_of :court_case_id, if: :formal?
        validates_presence_of :initial_payment_date, if: :variable_payment?
        belongs_to :court_case, optional: true, class_name: 'Hackney::Income::Models::CourtCase'
        has_many :agreement_states, class_name: 'Hackney::Income::Models::AgreementState'
        enum agreement_type: { informal: 'informal', formal: 'formal' }
        enum frequency: { weekly: 0, monthly: 1, fortnightly: 2, '4 weekly': 3, unsupported_legacy_frequency: 4, one_off: 5 }

        def active?
          ACTIVE_STATES.include?(current_state)
        end

        def formal?
          agreement_type == 'formal'
        end

        def informal?
          !formal?
        end

        def last_checked
          Hackney::Income::Models::AgreementState.where(agreement_id: id).last&.updated_at
        end

        def breached?
          current_state == 'breached'
        end

        def live?
          current_state == 'live'
        end

        def cancelled?
          current_state == 'cancelled'
        end

        def completed?
          current_state == 'completed'
        end

        def variable_payment?
          initial_payment_amount.present?
        end
      end
    end
  end
end
