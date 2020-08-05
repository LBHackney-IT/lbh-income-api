module Hackney
  module Income
    module Models
      class AgreementState < ApplicationRecord
        after_create :update_current_state_of_agreement

        validates_presence_of :agreement_state, :agreement_id
        belongs_to :agreement, class_name: 'Hackney::Income::Models::Agreement'
        enum agreement_state: { live: 'live', breached: 'breached', cancelled: 'cancelled', completed: 'completed' }

        private

        def update_current_state_of_agreement
          agreement.update!(current_state: agreement_state)
        end
      end
    end
  end
end
