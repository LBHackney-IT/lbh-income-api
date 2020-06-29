module Hackney
  module Income
    module Models
      class AgreementState < ApplicationRecord
        validates_presence_of :agreement_state, :agreement_id
        belongs_to :agreement, class_name: 'Hackney::Income::Models::Agreement'
        enum agreement_state: { live: 'live', breached: 'breached', cancelled: 'cancelled', completed: 'completed' }
      end
    end
  end
end
