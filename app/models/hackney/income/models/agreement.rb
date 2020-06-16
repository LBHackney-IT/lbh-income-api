module Hackney
  module Income
    module Models
      class Agreement < ApplicationRecord
        has_many :agreement_states, class_name: 'Hackney::Income::Models::AgreementState'
        enum agreement_type: { informal: 'informal', formal: 'formal' }
        enum frequency: { weekly: 0, monthly: 1 }
      end
    end
  end
end
